require "test_helper"
require "google_json_formatter"
require "cloud_error_reporter"

# Workshop Step 8, Quest 2: each unhandled exception must reach Error Reporting once, as an event
# named after the exception class and message (live, the old log format gave groups named after a
# stack frame, with the message "undefined" and the response code 0).
class CloudErrorReporterTest < ActiveSupport::TestCase
  class DeliberateError < StandardError; end

  class FailingJob < ApplicationJob
    def perform = raise(DeliberateError, "job failed on purpose")
  end

  Controller = Struct.new(:request)

  setup do
    @log = StringIO.new
    @logger = ActiveSupport::Logger.new(@log)
    @logger.formatter = GoogleJsonFormatter.new
    @reporter = CloudErrorReporter.new(logger: @logger)
  end

  test "an unhandled error becomes one ERROR entry typed as an Error Reporting event" do
    @reporter.report(raised, handled: false, severity: :error, context: {})

    entries = json_entries
    assert_equal 1, entries.size
    assert_equal "ERROR", entries.first["severity"]
    assert_equal "type.googleapis.com/google.devtools.clouderrorreporting.v1beta1.ReportedErrorEvent", entries.first["@type"]
  end

  test "the message is the exception in Ruby's own format, with paths relative to the app" do
    message = @reporter.event(raised)["message"]

    assert_match(/\Atest\/lib\/cloud_error_reporter_test\.rb:\d+:in '[^']+': deliberate \(CloudErrorReporterTest::DeliberateError\)$/, message)
    assert_match(/^\tfrom test\/lib\/cloud_error_reporter_test\.rb:\d+:in '/, message)
    assert_not_includes message, Rails.root.to_s
  end

  test "names the Cloud Run service and revision" do
    with_env("K_SERVICE" => "blog", "K_REVISION" => "blog-00012-abc") do
      assert_equal({ "service" => "blog", "version" => "blog-00012-abc" }, @reporter.event(raised)["serviceContext"])
    end
  end

  test "outside Cloud Run the service is the Rails application name" do
    with_env("K_SERVICE" => nil, "K_REVISION" => nil) do
      assert_equal({ "service" => Rails.application.name }, @reporter.event(raised)["serviceContext"])
    end
  end

  test "a request error carries the method, the filtered URL, the user agent, the status code and the user id" do
    env = Rails.application.env_config.merge(
      Rack::MockRequest.env_for("https://blog.example/posts/1?token=s3cr3t",
                                "HTTP_USER_AGENT" => "curl/8.7.1", "HTTP_REFERER" => "https://blog.example/")
    )
    controller = Controller.new(ActionDispatch::Request.new(env))

    Current.set(session: Session.new(user: users(:one))) do
      context = @reporter.event(raised, controller:)["context"]

      assert_equal({ "method" => "GET", "url" => "https://blog.example/posts/1?token=[FILTERED]", "userAgent" => "curl/8.7.1",
                     "referrer" => "https://blog.example/", "responseStatusCode" => 500 }, context["httpRequest"])
      assert_equal users(:one).id.to_s, context["user"]
    end
  end

  test "a job error has no request context" do
    assert_nil @reporter.event(raised, job: FailingJob.new)["context"]
  end

  test "handled errors (Rails.error.handle) are warnings, not crashes: nothing is reported" do
    @reporter.report(raised, handled: true, severity: :warning, context: {})

    assert_empty @log.string
  end

  test "install subscribes the reporter to Rails errors" do
    error_reporter = ActiveSupport::ErrorReporter.new
    previous_cleaner = ActiveJob::LogSubscriber.backtrace_cleaner

    CloudErrorReporter.install(error_reporter:, logger: @logger)
    error_reporter.report(raised, handled: false)

    assert_equal [ CloudErrorReporter::REPORTED_ERROR_EVENT ], json_entries.map { |entry| entry["@type"] }
  ensure
    ActiveJob::LogSubscriber.backtrace_cleaner = previous_cleaner
  end

  test "after install, Active Job's error line keeps the job and the exception but not the frames" do
    # Otherwise Error Reporting would count the line as a second event for the same failure.
    previous_cleaner = ActiveJob::LogSubscriber.backtrace_cleaner
    CloudErrorReporter.install(error_reporter: ActiveSupport::ErrorReporter.new, logger: @logger)
    Rails.logger.broadcast_to(@logger)

    assert_raises(DeliberateError) { FailingJob.perform_now }

    line = json_entries.find { |entry| entry["message"].start_with?("Error performing") }
    assert line, "expected Active Job's error line in #{json_entries.map { _1["message"] }}"
    assert_match(/CloudErrorReporterTest::FailingJob .*DeliberateError \(job failed on purpose\)/, line["message"])
    assert_not_includes line["message"], "cloud_error_reporter_test.rb:"
  ensure
    Rails.logger.stop_broadcasting_to(@logger)
    ActiveJob::LogSubscriber.backtrace_cleaner = previous_cleaner
  end

  private
    def raised
      raise DeliberateError, "deliberate"
    rescue DeliberateError => error
      error
    end

    def json_entries
      @log.string.lines.map { |line| JSON.parse(line) }
    end

    def with_env(values)
      saved = values.keys.to_h { |key| [ key, ENV[key] ] }
      values.each { |key, value| ENV[key] = value }
      yield
    ensure
      saved.each { |key, value| ENV[key] = value }
    end
end
