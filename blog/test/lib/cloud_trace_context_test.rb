require "test_helper"
require "cloud_trace_context"

class CloudTraceContextTest < ActiveSupport::TestCase
  TRACE = "c1b2c3d4e5f60718293a4b5c6d7e8f92"

  test "reads X-Cloud-Trace-Context as Cloud Run forwards it (decimal span id)" do
    # Captured live on Cloud Run: the container received ".../7132420986287306259;o=1" and the
    # request log of the same request had spanId "62fb73190c323613" (the same number in hex).
    context = CloudTraceContext.parse("HTTP_X_CLOUD_TRACE_CONTEXT" => "#{TRACE}/7132420986287306259;o=1")

    assert_equal TRACE, context.trace_id
    assert_equal "62fb73190c323613", context.span_id
    assert context.sampled
  end

  test "reads a W3C traceparent header" do
    context = CloudTraceContext.parse("HTTP_TRACEPARENT" => "00-#{TRACE}-2222222222222222-01")

    assert_equal TRACE, context.trace_id
    assert_equal "2222222222222222", context.span_id
    assert context.sampled
  end

  test "a traceparent with flags 00 is not sampled" do
    context = CloudTraceContext.parse("HTTP_TRACEPARENT" => "00-#{TRACE}-2222222222222222-00")

    assert_not context.sampled
  end

  test "prefers X-Cloud-Trace-Context, which carries the span of the Cloud Run request log" do
    context = CloudTraceContext.parse(
      "HTTP_TRACEPARENT" => "00-#{TRACE}-2222222222222222-01",
      "HTTP_X_CLOUD_TRACE_CONTEXT" => "#{TRACE}/7132420986287306259;o=1"
    )

    assert_equal "62fb73190c323613", context.span_id
  end

  test "an X-Cloud-Trace-Context without span or options still gives the trace" do
    context = CloudTraceContext.parse("HTTP_X_CLOUD_TRACE_CONTEXT" => TRACE.upcase)

    assert_equal TRACE, context.trace_id
    assert_nil context.span_id
    assert_not context.sampled
  end

  test "falls back to traceparent when X-Cloud-Trace-Context is malformed" do
    context = CloudTraceContext.parse(
      "HTTP_X_CLOUD_TRACE_CONTEXT" => "not-a-trace",
      "HTTP_TRACEPARENT" => "00-#{TRACE}-2222222222222222-01"
    )

    assert_equal TRACE, context.trace_id
  end

  test "ignores missing, malformed and all-zero headers" do
    [
      {},
      { "HTTP_X_CLOUD_TRACE_CONTEXT" => "" },
      { "HTTP_X_CLOUD_TRACE_CONTEXT" => "garbage" },
      { "HTTP_X_CLOUD_TRACE_CONTEXT" => "#{"0" * 32}/1;o=1" },
      { "HTTP_TRACEPARENT" => "00-#{"0" * 32}-2222222222222222-01" },
      { "HTTP_TRACEPARENT" => "ff-#{TRACE}-2222222222222222-01" },
      { "HTTP_TRACEPARENT" => "00-#{TRACE}-#{"0" * 16}-01" },
      { "HTTP_TRACEPARENT" => "00-#{TRACE}" }
    ].each do |env|
      assert_nil CloudTraceContext.parse(env), "expected no trace context for #{env.inspect}"
    end
  end

  test "drops a span id that does not fit in 64 bits but keeps the trace" do
    context = CloudTraceContext.parse("HTTP_X_CLOUD_TRACE_CONTEXT" => "#{TRACE}/#{2**64};o=1")

    assert_equal TRACE, context.trace_id
    assert_nil context.span_id
  end

  test "the middleware exposes the trace on Current while the request runs" do
    seen = nil
    app = ->(_env) { seen = [ Current.trace_id, Current.span_id, Current.trace_sampled ]; [ 200, {}, [ "ok" ] ] }

    CloudTraceContext.new(app).call("HTTP_X_CLOUD_TRACE_CONTEXT" => "#{TRACE}/1;o=1")

    assert_equal [ TRACE, "0000000000000001", true ], seen
  end

  test "the middleware leaves Current alone when there is no trace header" do
    seen = :not_called
    app = ->(_env) { seen = Current.trace_id; [ 200, {}, [ "ok" ] ] }

    CloudTraceContext.new(app).call({})

    assert_nil seen
  end
end
