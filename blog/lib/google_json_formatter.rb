# frozen_string_literal: true

require "json"
require "time"

# GoogleJsonFormatter formats standard Rails log messages as single-line JSON records
# adhering to Google Cloud Logging's structured logging format:
# https://cloud.google.com/logging/docs/structured-logging
#
# On Cloud Run the logging agent turns each line into a LogEntry: `severity` and `time` become the
# entry's severity and timestamp, the `logging.googleapis.com/*` keys become its trace, spanId and
# traceSampled (so the line is grouped with the request log of the same request), and when only
# `message` is left the entry shows it as textPayload.
class GoogleJsonFormatter < ActiveSupport::Logger::SimpleFormatter
  SEVERITY_MAP = {
    "DEBUG"   => "DEBUG",
    "INFO"    => "INFO",
    "WARN"    => "WARNING",
    "ERROR"   => "ERROR",
    "FATAL"   => "CRITICAL",
    "UNKNOWN" => "DEFAULT"
  }.freeze

  # Terminal colors (e.g. "\e[36m") that Rails log subscribers add; they are noise in Cloud Logging.
  ANSI_ESCAPE = /\e\[[\d;]*m/

  def call(severity, timestamp, progname, msg)
    gcp_severity = SEVERITY_MAP[severity.to_s.upcase] || severity.to_s.upcase

    payload = {
      severity: gcp_severity,
      # Microseconds, like Cloud Run's own request log: whole seconds would shuffle the lines of a request.
      time: (timestamp.respond_to?(:getutc) ? timestamp : Time.now).getutc.iso8601(6),
      message: format_message(msg).gsub(ANSI_ESCAPE, "")
    }

    payload[:progname] = progname.to_s if progname && !progname.empty?
    payload.merge!(trace_fields)

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

  # Trace of the current request (set by CloudTraceContext), empty outside a request.
  def trace_fields
    return {} unless defined?(Current) && Current.respond_to?(:trace_id)

    trace_id = Current.trace_id
    return {} if trace_id.blank?

    project_id = ENV["GOOGLE_CLOUD_PROJECT"].presence || ENV["GCP_PROJECT"].presence
    fields = { "logging.googleapis.com/trace" => project_id ? "projects/#{project_id}/traces/#{trace_id}" : trace_id }
    fields["logging.googleapis.com/spanId"] = Current.span_id if Current.span_id.present?
    fields["logging.googleapis.com/trace_sampled"] = Current.trace_sampled == true
    fields
  end
end
