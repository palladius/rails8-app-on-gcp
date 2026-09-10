# frozen_string_literal: true

# CloudErrorReportingMiddleware (Issue #82)
# Emits unhandled exceptions and backtraces directly to STDERR so Google Cloud Error Reporting
# on Cloud Run automatically ingests and groups crashes without requiring external heavy gems.
class CloudErrorReportingMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue Exception => e
    trace_id = (defined?(Current) && Current.respond_to?(:trace_id) && Current.trace_id) || env["HTTP_X_CLOUD_TRACE_CONTEXT"]
    $stderr.puts "[Google Cloud Error Reporting] #{e.class}: #{e.message}"
    $stderr.puts "Trace: #{trace_id}" if trace_id && !trace_id.empty?
    $stderr.puts e.backtrace.join("\n") if e.backtrace
    raise e
  end
end

Rails.application.config.middleware.use CloudErrorReportingMiddleware
