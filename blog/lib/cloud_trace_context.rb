# frozen_string_literal: true

# Reads the trace id Cloud Run's front end attaches to every request, so each log
# line of that request carries `logging.googleapis.com/trace` (lib/google_json_formatter.rb)
# and Logs Explorer can show all lines of one request together, next to its request log.
module CloudTraceContext
  # X-Cloud-Trace-Context: TRACE_ID/SPAN_ID;o=OPTIONS
  CLOUD_TRACE = %r{\A(\h{32})(?:/|\z)}
  # traceparent (W3C): VERSION-TRACE_ID-PARENT_ID-FLAGS
  TRACEPARENT = /\A\h{2}-(\h{32})-\h{16}-\h{2}\z/

  module_function

  def trace_id_from(env)
    env["HTTP_X_CLOUD_TRACE_CONTEXT"].to_s[CLOUD_TRACE, 1] ||
      env["HTTP_TRACEPARENT"].to_s[TRACEPARENT, 1]
  end

  class Middleware
    def initialize(app)
      @app = app
    end

    # Current is reset by the Rails executor after each request.
    def call(env)
      Current.trace_id = CloudTraceContext.trace_id_from(env)
      @app.call(env)
    end
  end
end
