require "test_helper"
require "google_json_formatter"

# Workshop Step 8, Quest 2: every Rails log line of a request must carry the trace of the Cloud Run
# request log, so "Show entries for this trace" in Logs Explorer groups them under the request.
class CloudLoggingTraceCorrelationTest < ActionDispatch::IntegrationTest
  TRACE = "c1b2c3d4e5f60718293a4b5c6d7e8f92"
  CLOUD_RUN_HEADER = { "X-Cloud-Trace-Context" => "#{TRACE}/7132420986287306259;o=1" }.freeze

  setup do
    @log = StringIO.new
    @json_logger = ActiveSupport::Logger.new(@log)
    @json_logger.formatter = GoogleJsonFormatter.new
    Rails.logger.broadcast_to(@json_logger)

    @previous_project = ENV["GOOGLE_CLOUD_PROJECT"]
    ENV["GOOGLE_CLOUD_PROJECT"] = "test-project"
  end

  teardown do
    Rails.logger.stop_broadcasting_to(@json_logger)
    ENV["GOOGLE_CLOUD_PROJECT"] = @previous_project
  end

  test "the trace middleware runs before Rails::Rack::Logger, so the Started line is correlated too" do
    stack = Rails.application.middleware.map(&:klass)

    assert_includes stack, CloudTraceContext
    assert_operator stack.index(CloudTraceContext), :<, stack.index(Rails::Rack::Logger)
  end

  test "every Rails log line of a request carries the Cloud Run trace and span" do
    get root_url, headers: CLOUD_RUN_HEADER
    assert_response :success

    lines = json_lines
    started = lines.find { |line| line["message"].start_with?("Started GET") }
    completed = lines.find { |line| line["message"].start_with?("Completed 200") }
    assert started, "expected a Started GET line in #{lines.map { _1["message"] }}"
    assert completed, "expected a Completed 200 line in #{lines.map { _1["message"] }}"

    [ started, completed ].each do |line|
      assert_equal "projects/test-project/traces/#{TRACE}", line["logging.googleapis.com/trace"]
      assert_equal "62fb73190c323613", line["logging.googleapis.com/spanId"]
      assert_equal true, line["logging.googleapis.com/trace_sampled"]
    end
  end

  test "the trace does not leak into lines logged after the request" do
    get root_url, headers: CLOUD_RUN_HEADER
    Rails.logger.info("after the request")

    after = json_lines.find { |line| line["message"] == "after the request" }
    assert_nil after["logging.googleapis.com/trace"]
  end

  private
    def json_lines
      @log.string.lines.map { |line| JSON.parse(line) }
    end
end
