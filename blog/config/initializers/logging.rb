# frozen_string_literal: true

# Google Cloud structured logging (Issue #82, workshop Step 8 Quest 2).
# production.rb installs GoogleJsonFormatter on Cloud Run; it emits one JSON object per line.
require "google_json_formatter"

# Trace correlation: read X-Cloud-Trace-Context / traceparent before Rails::Rack::Logger writes
# "Started GET ...", so every line of the request carries the trace of the Cloud Run request log.
# Harmless everywhere else: without those headers it does nothing.
require "cloud_trace_context"
Rails.application.config.middleware.insert_before Rails::Rack::Logger, CloudTraceContext

# Enable Google Cloud structured JSON logging locally in any environment when LOG_FORMAT=json
if ENV["LOG_FORMAT"] == "json" && !Rails.env.production?
  Rails.logger.formatter = GoogleJsonFormatter.new
end

# Error Reporting: wherever logs are Google Cloud JSON, each unhandled exception (request or job)
# is written once as an Error Reporting event, named after its class and message.
if Rails.logger.formatter.is_a?(GoogleJsonFormatter)
  require "cloud_error_reporter"
  CloudErrorReporter.install
end
