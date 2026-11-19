# frozen_string_literal: true

# CloudTraceContext (workshop Step 8, Quest 2) reads the trace of the incoming request and keeps it
# on Current for the duration of the request, so GoogleJsonFormatter can stamp every log line with
# `logging.googleapis.com/trace` and `logging.googleapis.com/spanId`. Logs Explorer then groups the
# Rails lines under the Cloud Run request log of the same request.
#
# Headers, in order of preference:
# - X-Cloud-Trace-Context: TRACE_ID/SPAN_ID;o=OPTIONS (span id in decimal). Cloud Run sets it on
#   every request, with the span id of its own request log entry (also when the client sent
#   only a W3C traceparent).
# - traceparent (W3C Trace Context): VERSION-TRACE_ID-PARENT_ID-FLAGS (ids in hex).
#
# The middleware sits before Rails::Rack::Logger so the "Started GET ..." line is correlated too.
# It runs inside ActionDispatch::Executor, which resets Current at the end of every request.
class CloudTraceContext
  Context = Data.define(:trace_id, :span_id, :sampled)

  CLOUD_TRACE_HEADER = %r{\A(?<trace>\h{32})(?:/(?<span>\d{1,20}))?(?:;o=(?<options>\d+))?\z}
  TRACEPARENT_HEADER = /\A(?<version>\h{2})-(?<trace>\h{32})-(?<span>\h{16})-(?<flags>\h{2})\z/
  ZERO_TRACE = "0" * 32
  ZERO_SPAN = "0" * 16
  MAX_SPAN = 2**64 - 1

  def self.parse(env)
    from_cloud_trace_context(env["HTTP_X_CLOUD_TRACE_CONTEXT"]) || from_traceparent(env["HTTP_TRACEPARENT"])
  end

  def self.from_cloud_trace_context(header)
    match = CLOUD_TRACE_HEADER.match(header.to_s.strip)
    return unless match

    trace_id = match[:trace].downcase
    return if trace_id == ZERO_TRACE

    span = match[:span]&.to_i
    span_id = format("%016x", span) if span&.between?(1, MAX_SPAN)
    Context.new(trace_id:, span_id:, sampled: match[:options].to_i.anybits?(1))
  end

  def self.from_traceparent(header)
    match = TRACEPARENT_HEADER.match(header.to_s.strip.downcase)
    return unless match
    return if match[:version] == "ff" || match[:trace] == ZERO_TRACE || match[:span] == ZERO_SPAN

    Context.new(trace_id: match[:trace], span_id: match[:span], sampled: match[:flags].hex.anybits?(1))
  end

  def initialize(app)
    @app = app
  end

  def call(env)
    if (context = self.class.parse(env))
      Current.trace_id = context.trace_id
      Current.span_id = context.span_id
      Current.trace_sampled = context.sampled
    end

    @app.call(env)
  end
end
