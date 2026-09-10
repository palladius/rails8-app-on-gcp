# frozen_string_literal: true

# Enable Google Cloud structured JSON logging locally in any environment when LOG_FORMAT=json
if ENV["LOG_FORMAT"] == "json" && !Rails.env.production?
  require "google_json_formatter"
  Rails.logger.formatter = GoogleJsonFormatter.new
end
