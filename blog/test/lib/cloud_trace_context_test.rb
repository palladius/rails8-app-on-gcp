require "test_helper"
require "cloud_trace_context"

class CloudTraceContextTest < ActiveSupport::TestCase
  test "reads the trace id from Cloud Run's X-Cloud-Trace-Context header" do
    env = { "HTTP_X_CLOUD_TRACE_CONTEXT" => "105445aa7843bc8bf206b12000100000/1;o=1" }
    assert_equal "105445aa7843bc8bf206b12000100000", CloudTraceContext.trace_id_from(env)
  end

  test "reads the trace id from a W3C traceparent header" do
    env = { "HTTP_TRACEPARENT" => "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01" }
    assert_equal "4bf92f3577b34da6a3ce929d0e0e4736", CloudTraceContext.trace_id_from(env)
  end

  test "ignores missing or malformed headers" do
    assert_nil CloudTraceContext.trace_id_from({})
    assert_nil CloudTraceContext.trace_id_from("HTTP_X_CLOUD_TRACE_CONTEXT" => "not a trace; rm -rf")
    assert_nil CloudTraceContext.trace_id_from("HTTP_TRACEPARENT" => "garbage")
  end

  test "middleware exposes the trace id to the request via Current" do
    seen = nil
    app = ->(_env) { seen = Current.trace_id; [ 200, {}, [ "ok" ] ] }

    CloudTraceContext::Middleware.new(app).call("HTTP_X_CLOUD_TRACE_CONTEXT" => "105445aa7843bc8bf206b12000100000/1;o=1")

    assert_equal "105445aa7843bc8bf206b12000100000", seen
  ensure
    Current.reset
  end
end
