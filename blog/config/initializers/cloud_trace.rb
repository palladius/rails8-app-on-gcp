# frozen_string_literal: true

require "cloud_trace_context"

# Puts Cloud Run's request trace id on Current, so every log line of a request
# (lib/google_json_formatter.rb) carries `logging.googleapis.com/trace`. That
# includes Rails' own exception log line, which Cloud Error Reporting ingests.
Rails.application.config.middleware.insert_after ActionDispatch::RequestId, CloudTraceContext::Middleware
