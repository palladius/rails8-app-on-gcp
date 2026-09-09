# frozen_string_literal: true

require "net/http"
require "uri"
require "time"
require "json"
require "shellwords"

module WorkshopHive
  class Healthchecker
    DEFAULT_TIMEOUT = 2.0 # Secondi max per ping /up e /status

    @results_cache = {}
    @cache_mutex = Mutex.new
    @poller_thread = nil
    @poller_mutex = Mutex.new

    def self.check(base_url, timeout_seconds: DEFAULT_TIMEOUT)
      parsed_uri = URI.parse(base_url.strip)
      
      # 1. Ping /up (o path specificato se diverso da root)
      up_uri = parsed_uri.dup
      if up_uri.path.nil? || up_uri.path.empty? || up_uri.path == "/"
        up_uri.path = "/up"
      end
      up_res = execute_http_get(up_uri, timeout_seconds)


      # 2. Se /up risponde, interroga /status per le metriche ricche
      status_data = {}
      if up_res[:status] == "up"
        status_uri = parsed_uri.dup
        status_uri.path = "/status.json"
        status_raw = execute_http_get(status_uri, timeout_seconds, headers: { "Accept" => "application/json" })

        if status_raw[:status] == "up" && status_raw[:body]
          begin
            parsed_json = JSON.parse(status_raw[:body])
            sys = parsed_json["system"] || {}
            step = parsed_json["workshop_step"] || {}
            db = parsed_json["database"] || {}
            storage = parsed_json["storage"] || {}
            ai = parsed_json["ai"] || {}
            run_env = parsed_json["run_env"] || {}

            # Infer K_SERVICE, K_REVISION and ADMIN_EMAIL from run_env or safe_environment array
            k_service = run_env["service_name"]
            k_revision = run_env["revision_name"]
            admin_email = nil
            if (safe_env = parsed_json["safe_environment"]).is_a?(Array)
              safe_env.each do |v|
                k_service ||= v["value"] if v["key"] == "K_SERVICE" && v["value"] != "nil"
                k_revision ||= v["value"] if v["key"] == "K_REVISION" && v["value"] != "nil"
                admin_email ||= v["value"] if v["key"] == "ADMIN_EMAIL" && v["value"] != "nil" && !v["value"].to_s.empty?
              end
            end

            status_data = {
              app_version: sys["app_version"],
              ruby_version: sys["ruby_version"],
              rails_version: sys["rails_version"],
              rails_env: sys["rails_env"],
              posts_count: sys["posts_count"],
              users_count: sys["admin_users_count"],
              blobs_count: sys["blobs_count"],
              attachments_count: sys["attachments_count"],
              git_commit: sys["git_commit"],
              pending_jobs: parsed_json.dig("jobs", "pending_count") || 0,
              failed_jobs: parsed_json.dig("jobs", "failed_count") || 0,
              step_number: step["number"],
              step_description: step["description"],
              db_tier: db["tier"] || db["badge"],
              db_badge: db["badge"],
              storage_tier: storage["tier"] || storage["badge"],
              storage_badge: storage["badge"],
              ai_badge: ai["badge"],
              k_service: k_service,
              k_revision: k_revision,
              admin_email: admin_email
            }
          rescue JSON::ParserError
            # Non è un json valido
          end
        end
      end

      # Se questo check non ha estratto telemetria (es. errore temporaneo, 500, timeout o down),
      # preserva la telemetria precedentemente memorizzata in cache invece di azzerarla a {}!
      if status_data.empty?
        previous_telemetry = @cache_mutex.synchronize { @results_cache.dig(base_url.strip, :telemetry) }
        status_data = previous_telemetry if previous_telemetry && !previous_telemetry.empty?
      end

      up_res.merge(telemetry: status_data)
    end

    def self.execute_http_get(uri, timeout_seconds, headers: {})
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      begin
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == "https")
        http.open_timeout = timeout_seconds
        http.read_timeout = timeout_seconds

        request = Net::HTTP::Get.new(uri.request_uri)
        request["User-Agent"] = "WorkshopHive-Telemetry/1.0"
        request["Connection"] = "close"
        headers.each { |k, v| request[k] = v }

        response = http.request(request)
        duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).round

        if response.code.to_i == 200
          return {
            status: "up",
            http_code: 200,
            latency_ms: duration_ms,
            body: response.body,
            checked_at: Time.now.utc.iso8601
          }
        else
          return {
            status: "down",
            http_code: response.code.to_i,
            latency_ms: duration_ms,
            checked_at: Time.now.utc.iso8601
          }
        end
      rescue StandardError => net_err
        # Fallback to curl: Cloud Run and Google Front End can occasionally hit Net::ReadTimeout in standard Ruby Net::HTTP
        begin
          header_args = headers.map { |k, v| "-H #{Shellwords.escape("#{k}: #{v}")}" }.join(" ")
          cmd = "curl -s -k --max-time #{timeout_seconds.to_i} -w \"\\n%{http_code}\" #{header_args} #{Shellwords.escape(uri.to_s)}"
          raw_output = `#{cmd}`
          duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).round

          if raw_output && !raw_output.empty?
            lines = raw_output.split("\n")
            http_code = lines.pop.to_i
            body = lines.join("\n")

            if http_code == 200
              return {
                status: "up",
                http_code: 200,
                latency_ms: duration_ms,
                body: body,
                checked_at: Time.now.utc.iso8601
              }
            elsif http_code > 0
              return {
                status: "down",
                http_code: http_code,
                latency_ms: duration_ms,
                checked_at: Time.now.utc.iso8601
              }
            end
          end
        rescue StandardError => curl_err
          # curl fallback also failed
        end

        {
          status: "down",
          http_code: nil,
          error: net_err.message,
          checked_at: Time.now.utc.iso8601
        }
      end
    end

    def self.check_all(urls, timeout_seconds: DEFAULT_TIMEOUT)
      threads = []
      results = {}
      mutex = Mutex.new

      urls.uniq.compact.reject(&:empty?).each do |url|
        threads << Thread.new do
          res = check(url, timeout_seconds: timeout_seconds)
          mutex.synchronize { results[url] = res }
        end
      end

      threads.each(&:join)

      @cache_mutex.synchronize do
        @results_cache.merge!(results)
      end

      results
    end

    # Ritorna ISTANTANEAMENTE (0ms) i risultati in cache se presenti,
    # e avvia un refresh in background in modo asincrono.
    def self.get_or_refresh_async(urls)
      current = cached_results

      # Avvia aggiornamento asincrono senza bloccare la risposta HTTP
      Thread.new do
        check_all(urls)
      end

      # Se non abbiamo mai fatto un check, facciamo il primo run sincrono
      if current.empty? && !urls.empty?
        check_all(urls)
      else
        current
      end
    end

    def self.cached_results
      @cache_mutex.synchronize { @results_cache.dup }
    end

    # Background continuous poller (ogni 5 secondi per background worker)
    def self.start_background_poller!(urls_proc, interval: 5)
      @poller_mutex.synchronize do
        return if @poller_thread&.alive?

        @poller_thread = Thread.new do
          loop do
            begin
              urls = urls_proc.call
              check_all(urls) if urls && !urls.empty?
            rescue StandardError => e
              warn "[Healthchecker Background Poller] #{e.message}"
            end
            sleep interval
          end
        end
      end
    end
  end
end
