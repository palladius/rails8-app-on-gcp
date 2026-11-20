require "test_helper"
require "google_json_formatter"
require "cloud_error_reporter"

# GET /boom is the intentional test exception of workshop Step 8, Quest 2. It must not be a public
# endpoint: anyone could flood Error Reporting (and the log bill) with it.
class BoomsControllerTest < ActionDispatch::IntegrationTest
  ENV_KEYS = %w[GOOGLE_CLOUD_ACCOUNT GOOGLE_CLOUD_EMAIL ADMIN_EMAIL IAP_MOCK_EMAIL GOOGLE_CLOUD_PROJECT].freeze
  TRACE = "c1b2c3d4e5f60718293a4b5c6d7e8f92"

  setup do
    @saved_env = ENV_KEYS.to_h { |key| [ key, ENV[key] ] }
    ENV_KEYS.each { |key| ENV.delete(key) }
    ENV["GOOGLE_CLOUD_ACCOUNT"] = users(:one).email_address # the admin that db/seeds.rb creates
  end

  teardown do
    @saved_env.each { |key, value| ENV[key] = value }
  end

  test "anonymous visitors are sent to the sign-in page instead of crashing the app" do
    get boom_url

    assert_redirected_to new_session_url
  end

  test "signed-in users who are not the workshop admin get a 404" do
    sign_in_as users(:two)

    get boom_url

    assert_response :not_found
  end

  test "nobody can trigger it when no admin email is configured" do
    ENV.delete("GOOGLE_CLOUD_ACCOUNT")
    sign_in_as users(:one)

    get boom_url

    assert_response :not_found
  end

  test "the workshop admin triggers a deliberate exception" do
    sign_in_as users(:one)

    assert_raises(BoomsController::DeliberateBoom) { get boom_url }
  end

  test "in production the crash is ONE Error Reporting event, named after the exception, with its request and trace" do
    sign_in_as users(:one)
    ENV["GOOGLE_CLOUD_PROJECT"] = "test-project"
    log = StringIO.new
    json_logger = ActiveSupport::Logger.new(log, level: :info) # production's default RAILS_LOG_LEVEL
    json_logger.formatter = GoogleJsonFormatter.new
    Rails.logger.broadcast_to(json_logger)
    reporter = CloudErrorReporter.new(logger: json_logger) # what config/initializers/logging.rb subscribes
    Rails.error.subscribe(reporter)
    env_config = Rails.application.env_config
    previous = env_config.slice("action_dispatch.show_exceptions", "action_dispatch.show_detailed_exceptions",
                                "action_dispatch.debug_exception_log_level")
    env_config.merge!("action_dispatch.show_exceptions" => :all, "action_dispatch.show_detailed_exceptions" => false,
                      "action_dispatch.debug_exception_log_level" => Logger::DEBUG) # as in production.rb
    stderr = StringIO.new
    original_stderr, $stderr = $stderr, stderr

    get boom_url, headers: { "X-Cloud-Trace-Context" => "#{TRACE}/1;o=1", "User-Agent" => "curl/8.7.1" }

    assert_response :internal_server_error
    entries = log.string.lines.map { |line| JSON.parse(line) }
    with_stack_trace = entries.select { |entry| entry["message"].to_s.include?("booms_controller.rb:") }
    assert_equal 1, with_stack_trace.size, "Error Reporting counts every entry with a stack trace: one per exception"
    event = with_stack_trace.first
    assert_equal "ERROR", event["severity"]
    assert_equal CloudErrorReporter::REPORTED_ERROR_EVENT, event["@type"]
    # Ruby's own format, from which Error Reporting reads the exception class and message.
    assert_match(/\Aapp\/controllers\/booms_controller\.rb:\d+:in 'BoomsController#show': 💥 Deliberate Boom.* \(BoomsController::DeliberateBoom\)$/,
                 event["message"])
    assert_equal({ "method" => "GET", "url" => boom_url, "userAgent" => "curl/8.7.1", "responseStatusCode" => 500 },
                 event.dig("context", "httpRequest"))
    assert_equal users(:one).id.to_s, event.dig("context", "user")
    assert_equal "projects/test-project/traces/#{TRACE}", event["logging.googleapis.com/trace"]
    assert_empty stderr.string, "nothing may be dumped frame by frame on stderr"
  ensure
    $stderr = original_stderr if original_stderr
    env_config&.merge!(previous) if previous
    Rails.error.unsubscribe(reporter) if reporter
    Rails.logger.stop_broadcasting_to(json_logger) if json_logger
  end
end
