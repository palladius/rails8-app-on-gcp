# frozen_string_literal: true

require "json"
require "time"

# GoogleJsonFormatter formats standard Rails log messages as single-line JSON records
# adhering to Google Cloud Logging's structured logging format:
# https://cloud.google.com/logging/docs/structured-logging
class GoogleJsonFormatter < ActiveSupport::Logger::SimpleFormatter
  SEVERITY_MAP = {
    "DEBUG"   => "DEBUG",
    "INFO"    => "INFO",
    "WARN"    => "WARNING",
    "ERROR"   => "ERROR",
    "FATAL"   => "CRITICAL",
    "UNKNOWN" => "DEFAULT"
  }.freeze

  def call(severity, timestamp, progname, msg)
    gcp_severity = SEVERITY_MAP[severity.to_s.upcase] || severity.to_s.upcase

    message_str = format_message(msg)

    payload = {
      severity: gcp_severity,
      time: timestamp.respond_to?(:iso8601) ? timestamp.iso8601 : Time.now.utc.iso8601,
      message: message_str
    }

    payload[:progname] = progname.to_s if progname && !progname.empty?

    trace_id = current_trace_id
    if trace_id && !trace_id.empty?
      project_id = ENV["GOOGLE_CLOUD_PROJECT"] || ENV["GCP_PROJECT"]
      if project_id && !project_id.empty?
        payload["logging.googleapis.com/trace"] = "projects/#{project_id}/traces/#{trace_id}"
      else
        payload["logging.googleapis.com/trace"] = trace_id
      end
    end

    payload.to_json + "\n"
  end

  private

  def format_message(msg)
    return "" if msg.nil?

    if msg.is_a?(Exception)
      formatted = "#{msg.class}: #{msg.message}"
      formatted += "\n" + msg.backtrace.join("\n") if msg.backtrace
      formatted
    elsif msg.is_a?(Hash)
      msg.to_json
    else
      msg.to_s
    end
  end

  def current_trace_id
    if defined?(Current) && Current.respond_to?(:trace_id) && Current.trace_id
      Current.trace_id
    elsif Thread.current[:gcp_trace_id]
      Thread.current[:gcp_trace_id]
    end
  end
end
