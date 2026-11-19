# frozen_string_literal: true

# Google Cloud structured logging (Issue #82, workshop Step 8 Quest 2).
# production.rb installs GoogleJsonFormatter on Cloud Run; it emits one JSON object per line.

# Trace correlation: read X-Cloud-Trace-Context / traceparent before Rails::Rack::Logger writes
# "Started GET ...", so every line of the request carries the trace of the Cloud Run request log.
# Harmless everywhere else: without those headers it does nothing.
require "cloud_trace_context"
Rails.application.config.middleware.insert_before Rails::Rack::Logger, CloudTraceContext

# Enable Google Cloud structured JSON logging locally in any environment when LOG_FORMAT=json
if ENV["LOG_FORMAT"] == "json" && !Rails.env.production?
  require "google_json_formatter"
  Rails.logger.formatter = GoogleJsonFormatter.new
end
