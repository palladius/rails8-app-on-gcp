# frozen_string_literal: true

require "net/http"
require "uri"
require "time"

module WorkshopHive
  class Healthchecker
    DEFAULT_TIMEOUT = 2.0 # Secondi max per ping /up

    @results_cache = {}
    @cache_mutex = Mutex.new

    def self.check(base_url, timeout_seconds: DEFAULT_TIMEOUT)
      uri = URI.parse(base_url.strip)
      # Assicura il path /up se non specificato
      uri.path = "/up" if uri.path.nil? || uri.path.empty? || uri.path == "/"

      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = timeout_seconds
      http.read_timeout = timeout_seconds

      request = Net::HTTP::Get.new(uri.request_uri)
      request["User-Agent"] = "WorkshopHive-Healthchecker/1.0"

      response = http.request(request)
      duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).round

      if response.code.to_i == 200
        {
          status: "up",
          http_code: 200,
          latency_ms: duration_ms,
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
