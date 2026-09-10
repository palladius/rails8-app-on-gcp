# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require "time"

module WorkshopHive
  module ProctorReviewer
    DEFAULT_PROCTORS = %w[palladius emilianodellacasa ricc].freeze
    CACHE_TTL_SECONDS = 120

    @cache = {}
    @cache_mutex = Mutex.new
    @github_api_base = nil

    class << self
      attr_accessor :github_api_base

      def allowed_proctors
        raw = ENV["HIVE_PROCTORS"]
        if raw.nil? || raw.strip.empty?
          DEFAULT_PROCTORS
        else
          raw.split(",").map { |p| p.strip.downcase }.reject(&:empty?)
        end
      end

      def reset_cache!
        @cache_mutex.synchronize { @cache.clear }
      end

      def review(issue_id, timeout_seconds: 4.0)
        id = issue_id.to_i
        return { status: :review_pending, reviewer: nil } if id <= 0

        now = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        @cache_mutex.synchronize do
          cached = @cache[id]
          if cached && (now - cached[:cached_at]) < CACHE_TTL_SECONDS
            return cached[:data]
          end
        end

        result = fetch_and_evaluate(id, timeout_seconds)

        @cache_mutex.synchronize do
          @cache[id] = {
            cached_at: now,
            data: result
          }
        end

        result
      end

      private

      def fetch_and_evaluate(issue_id, timeout_seconds)
        base = @github_api_base || "https://api.github.com"
        endpoint = "#{base}/repos/palladius/rails8-app-on-gcp/issues/#{issue_id}/comments"
        uri = URI.parse(endpoint)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == "https")
        http.open_timeout = timeout_seconds
        http.read_timeout = timeout_seconds

        req = Net::HTTP::Get.new(uri.request_uri)
        req["User-Agent"] = "WorkshopHive-ProctorReviewer/1.0"
        req["Accept"] = "application/vnd.github.v3+json"
        if ENV["GITHUB_TOKEN"].to_s.strip != ""
          req["Authorization"] = "token #{ENV['GITHUB_TOKEN'].strip}"
        end

        res = http.request(req)
        return { status: :review_pending, reviewer: nil } unless res.code.to_i == 200

        comments = JSON.parse(res.body)
        return { status: :review_pending, reviewer: nil } unless comments.is_a?(Array)

        proctors = allowed_proctors

        # Check in reverse chronological order (latest comment first)
        approved_comment = comments.reverse.find do |c|
          user_login = c.dig("user", "login").to_s.downcase
          body = c["body"].to_s
          proctors.include?(user_login) && body.match?(/\bLGTM\b/i)
        end

        if approved_comment
          {
            status: :lgtm_approved,
            reviewer: approved_comment.dig("user", "login"),
            approved_at: approved_comment["created_at"]
          }
        else
          {
            status: :review_pending,
            reviewer: nil
          }
        end
      rescue StandardError => e
        {
          status: :review_pending,
          reviewer: nil,
          error: e.message
        }
      end
    end
  end
end
