# frozen_string_literal: true

require "net/http"
require "uri"
require "time"
require "json"

module WorkshopHive
  class Healthchecker
    DEFAULT_TIMEOUT = 2.5 # Secondi max per ping /up e /status

    @results_cache = {}
    @cache_mutex = Mutex.new

    def self.check(base_url, timeout_seconds: DEFAULT_TIMEOUT)
      parsed_uri = URI.parse(base_url.strip)
      
      # 1. Ping /up
      up_uri = parsed_uri.dup
      up_uri.path = "/up"
      up_res = execute_http_get(up_uri, timeout_seconds)

      # 2. Se /up risponde (o proviamo comunque), interroga /status per le metriche ricche (Ruby, Rails, Step, N posts, N users, ecc.)
      status_data = {}
      if up_res[:status] == "up"
        status_uri = parsed_uri.dup
        status_uri.path = "/status"
        status_raw = execute_http_get(status_uri, timeout_seconds, headers: { "Accept" => "application/json" })

        if status_raw[:status] == "up" && status_raw[:body]
          begin
            parsed_json = JSON.parse(status_raw[:body])
            sys = parsed_json["system"] || {}
            step = parsed_json["workshop_step"] || {}
            db = parsed_json["database"] || {}
            storage = parsed_json["storage"] || {}
            ai = parsed_json["ai"] || {}

            status_data = {
              app_version: sys["app_version"],
              ruby_version: sys["ruby_version"],
              rails_version: sys["rails_version"],
              posts_count: sys["posts_count"],
              users_count: sys["admin_users_count"],
              blobs_count: sys["blobs_count"],
              attachments_count: sys["attachments_count"],
              step_number: step["number"],
              step_description: step["description"],
              db_tier: db["badge"],
              storage_tier: storage["badge"],
              ai_badge: ai["badge"]
            }
          rescue JSON::ParserError
            # Non è un json valido, proseguiamo
          end
        end
      end

      up_res.merge(telemetry: status_data)
    end

    def self.execute_http_get(uri, timeout_seconds, headers: {})
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = timeout_seconds
      http.read_timeout = timeout_seconds

      request = Net::HTTP::Get.new(uri.request_uri)
      request["User-Agent"] = "WorkshopHive-Telemetry/1.0"
      headers.each { |k, v| request[k] = v }

      response = http.request(request)
      duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).round

      if response.code.to_i == 200
        {
          status: "up",
          http_code: 200,
          latency_ms: duration_ms,
          body: response.body,
          checked_at: Time.now.utc.iso8601
        }
      else
        {
          status: "down",
          http_code: response.code.to_i,
          latency_ms: duration_ms,
          checked_at: Time.now.utc.iso8601
        }
      end
    rescue StandardError => e
      {
        status: "down",
        http_code: nil,
        error: e.message,
        checked_at: Time.now.utc.iso8601
      }
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

    def self.cached_results
      @cache_mutex.synchronize { @results_cache.dup }
    end
  end
end
