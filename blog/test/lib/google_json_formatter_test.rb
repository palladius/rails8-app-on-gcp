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
    assert_equal "2026-09-10T12:00:00Z", payload["time"]
    assert_equal "Starting server", payload["message"]
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
end
