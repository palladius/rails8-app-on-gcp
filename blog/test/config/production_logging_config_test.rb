require "test_helper"
require "google_json_formatter"
require "cloud_error_reporter"

# Workshop Step 8, Quest 2. The test environment cannot boot config/environments/production.rb,
# so the settings are checked as text and their effect is checked with the same values here.
class ProductionLoggingConfigTest < ActionDispatch::IntegrationTest
  PRODUCTION_RB = Rails.root.join("config/environments/production.rb").read

  test "production does not log 4xx exceptions (404, 422 CSRF) as ERROR entries" do
    # Verified live: with the default (true), GET /posts/999999999 logged
    # "ActiveRecord::RecordNotFound (...)" with a stack trace at ERROR, and Error Reporting
    # opened an error group for that plain 404. Cloud Run's request log already records
    # 4xx responses (at WARNING).
    assert_match(/^\s*config\.action_dispatch\.log_rescued_responses\s*=\s*false\b/, PRODUCTION_RB)
  end

  test "with that setting a 404 leaves nothing for Error Reporting to pick up" do
    log = StringIO.new
    json_logger = ActiveSupport::Logger.new(log)
    json_logger.formatter = GoogleJsonFormatter.new
    Rails.logger.broadcast_to(json_logger)
    reporter = CloudErrorReporter.new(logger: json_logger)
    Rails.error.subscribe(reporter)
    env_config = Rails.application.env_config
    previous = env_config.slice("action_dispatch.show_exceptions", "action_dispatch.show_detailed_exceptions",
                                "action_dispatch.log_rescued_responses")
    env_config.merge!("action_dispatch.show_exceptions" => :all,
                      "action_dispatch.show_detailed_exceptions" => false,
                      "action_dispatch.log_rescued_responses" => false)

    get post_url(id: 999_999_999)

    assert_response :not_found
    entries = log.string.lines.map { |line| JSON.parse(line) }
    assert_not_includes entries.map { |entry| entry["severity"] }, "ERROR"
    # On Cloud Run, Error Reporting reads any entry with a stack trace, whatever its severity.
    assert_empty entries.select { |entry| entry["@type"] || entry["message"].to_s.include?("posts_controller.rb:") }
  ensure
    env_config&.merge!(previous) if previous
    Rails.error.unsubscribe(reporter) if reporter
    Rails.logger.stop_broadcasting_to(json_logger) if json_logger
  end

  test "production writes Rails' own copy of an exception at DEBUG: CloudErrorReporter already reports it" do
    # Verified live: Rails' "Class (message):" + backtrace entry became an Error Reporting group named
    # after a stack frame, with the message "undefined". booms_controller_test.rb checks that, with this
    # setting, /boom leaves exactly one entry with a stack trace: CloudErrorReporter's event.
    assert_match(/^\s*config\.action_dispatch\.debug_exception_log_level\s*=\s*:debug\b/, PRODUCTION_RB)
  end

  test "the stderr dump middleware is gone: an exception is one structured entry, not one entry per frame" do
    # Verified live: CloudErrorReportingMiddleware printed each backtrace frame on its own
    # stderr line, about 80 DEFAULT-severity log entries per exception.
    assert_not Rails.application.middleware.any? { |middleware| middleware.name == "CloudErrorReportingMiddleware" }
  end
end
