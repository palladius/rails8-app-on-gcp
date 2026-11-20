require "test_helper"
require "google_json_formatter"

class GoogleJsonFormatterTest < ActiveSupport::TestCase
  setup do
    @formatter = GoogleJsonFormatter.new
    @time = Time.utc(2026, 9, 10, 12, 0, 0)
  end

  test "formats simple info message into valid JSON with newline" do
    output = @formatter.call("INFO", @time, "Rails", "Starting server")
    assert output.end_with?("\n"), "Log output must terminate with newline"

    payload = JSON.parse(output)
    assert_equal "INFO", payload["severity"]
    assert_equal "2026-09-10T12:00:00.000000Z", payload["time"]
    assert_equal "Starting server", payload["message"]
  end

  test "keeps microsecond precision so the lines of one request stay in order" do
    # Cloud Run stamps its request log to the microsecond. With whole seconds, the Started /
    # Processing / Completed lines of a request share one timestamp and can show up shuffled.
    time = Time.utc(2026, 9, 10, 12, 0, 0, 123456)
    payload = JSON.parse(@formatter.call("INFO", time, nil, "tick"))
    assert_equal "2026-09-10T12:00:00.123456Z", payload["time"]
  end

  test "strips ANSI color codes that Rails log subscribers add" do
    # Seen live on the worker: "[36m  GCS Storage (203.5ms) [0m[34mDownloaded file ...[0m"
    colored = "\e[1m\e[36m  GCS Storage (203.5ms)\e[0m \e[34mDownloaded file from key: abc\e[0m"
    payload = JSON.parse(@formatter.call("INFO", @time, nil, colored))
    assert_equal "  GCS Storage (203.5ms) Downloaded file from key: abc", payload["message"]
  end

  test "maps severities correctly to Cloud Logging standards" do
    {
      "DEBUG" => "DEBUG",
      "INFO" => "INFO",
      "WARN" => "WARNING",
      "ERROR" => "ERROR",
      "FATAL" => "CRITICAL"
    }.each do |rails_severity, gcp_severity|
      payload = JSON.parse(@formatter.call(rails_severity, @time, nil, "test"))
      assert_equal gcp_severity, payload["severity"], "Expected #{rails_severity} to map to #{gcp_severity}"
    end
  end

  test "handles Exception objects passed as message" do
    err = StandardError.new("Database connection lost")
    err.set_backtrace(["app/models/post.rb:10:in 'find'", "app/controllers/posts_controller.rb:5:in 'show'"])

    output = @formatter.call("ERROR", @time, nil, err)
    payload = JSON.parse(output)

    assert_equal "ERROR", payload["severity"]
    assert_includes payload["message"], "StandardError: Database connection lost"
    assert_includes payload["message"], "app/models/post.rb:10"
  end

  test "writes a Hash message as structured fields (jsonPayload), not as a JSON string" do
    payload = JSON.parse(@formatter.call("INFO", @time, nil, { message: "Paid \e[32morder\e[0m", order_id: 42 }))

    assert_equal "Paid order", payload["message"]
    assert_equal 42, payload["order_id"]
  end

  test "a Hash message cannot override the severity or the time of the line" do
    payload = JSON.parse(@formatter.call("ERROR", @time, nil, { "severity" => "DEBUG", "time" => "yesterday", "message" => "x" }))

    assert_equal "ERROR", payload["severity"]
    assert_equal "2026-09-10T12:00:00.000000Z", payload["time"]
  end

  test "handles nil and empty messages gracefully" do
    output = @formatter.call("INFO", @time, nil, nil)
    payload = JSON.parse(output)
    assert_equal "", payload["message"]
  end

  test "injects Google Cloud Trace ID if trace context is present" do
    # When trace context is set in Current or ENV
    trace_id = "105445aa7843bc8bf206b120001000"
    project_id = "my-gcp-project"

    begin
      ENV["GOOGLE_CLOUD_PROJECT"] = project_id
      Current.trace_id = trace_id if defined?(Current.trace_id)

      # Formatter should include logging.googleapis.com/trace
      output = @formatter.call("INFO", @time, nil, "Trace test")
      payload = JSON.parse(output)
      assert_equal "projects/#{project_id}/traces/#{trace_id}", payload["logging.googleapis.com/trace"]
    ensure
      ENV.delete("GOOGLE_CLOUD_PROJECT")
      Current.trace_id = nil if defined?(Current.trace_id)
    end
  end

  test "adds the Cloud Run span and sampling flag so the line nests under the request in Cloud Trace" do
    with_project("my-gcp-project") do
      Current.set(trace_id: "c1b2c3d4e5f60718293a4b5c6d7e8f92", span_id: "62fb73190c323613", trace_sampled: true) do
        payload = JSON.parse(@formatter.call("INFO", @time, nil, "inside a request"))

        assert_equal "projects/my-gcp-project/traces/c1b2c3d4e5f60718293a4b5c6d7e8f92", payload["logging.googleapis.com/trace"]
        assert_equal "62fb73190c323613", payload["logging.googleapis.com/spanId"]
        assert_equal true, payload["logging.googleapis.com/trace_sampled"]
      end
    end
  end

  test "omits every trace field outside a request (boot, Solid Queue worker)" do
    with_project("my-gcp-project") do
      payload = JSON.parse(@formatter.call("INFO", @time, nil, "SolidQueue-1.4.0 Started Worker"))

      assert_empty payload.keys.grep(/\Alogging\.googleapis\.com/)
    end
  end

  private
    def with_project(project_id)
      previous = ENV["GOOGLE_CLOUD_PROJECT"]
      ENV["GOOGLE_CLOUD_PROJECT"] = project_id
      yield
    ensure
      ENV["GOOGLE_CLOUD_PROJECT"] = previous
    end
end
