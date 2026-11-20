# frozen_string_literal: true

# CloudErrorReporter (workshop Step 8, Quest 2) turns every unhandled exception into ONE Google Cloud
# Error Reporting event: a structured log entry, no client library, no extra IAM role.
# https://cloud.google.com/error-reporting/docs/formatting-error-messages
#
# It is a Rails error subscriber (https://guides.rubyonrails.org/error_reporting.html), the same hook
# Sentry or Honeybadger use: Rails calls it for unhandled exceptions in requests and in Solid Queue
# jobs. config/initializers/logging.rb subscribes it wherever logs are Google Cloud JSON.
#
# The entry it writes (GoogleJsonFormatter adds severity, time and the request's trace):
# - `@type` ReportedErrorEvent: Error Reporting takes the entry as an error event.
# - `message`: the exception in Ruby's own format, "file:line:in 'method': message (Class)" then
#   "\tfrom ..." lines, so the group is named after the exception class and message.
# - `context.httpRequest`: method, URL and the status code the visitor got (500 for most exceptions).
# - `context.user`: the signed-in user's id, so Error Reporting counts affected users without emails.
#
# Rails also logs each exception itself, with a backtrace that Error Reporting would count as a second
# event: production.rb lowers ActionDispatch's copy to DEBUG, and .install drops the frames from
# Active Job's "Error performing ..." line.
class CloudErrorReporter
  REPORTED_ERROR_EVENT = "type.googleapis.com/google.devtools.clouderrorreporting.v1beta1.ReportedErrorEvent"

  # Silences every frame: Active Job's error line keeps "Error performing FooJob ...: Class (message)"
  # and loses the backtrace, which this reporter already sends.
  NO_FRAMES = ActiveSupport::BacktraceCleaner.new.tap { |cleaner| cleaner.add_silencer { true } }

  def self.install(error_reporter: Rails.error, logger: Rails.logger)
    error_reporter.subscribe(new(logger:))
    ActiveSupport.on_load(:active_job) { ActiveJob::LogSubscriber.backtrace_cleaner = NO_FRAMES }
  end

  def initialize(logger: Rails.logger, root: Rails.root)
    @logger = logger
    @root_prefix = "#{root}/"
  end

  # Rails error subscriber API. Handled errors (Rails.error.handle) default to :warning: the code
  # chose to carry on, so they are not crashes to page anyone about.
  def report(error, handled:, severity:, context:, source: nil)
    return unless severity == :error

    @logger.error(event(error, context))
  end

  def event(error, context = {})
    {
      "@type" => REPORTED_ERROR_EVENT,
      "message" => error.full_message(highlight: false, order: :top).gsub(@root_prefix, ""),
      "serviceContext" => service_context,
      "context" => event_context(error, context)
    }.compact
  end

  private
    # Cloud Run sets K_SERVICE and K_REVISION; Error Reporting shows them as "service:version".
    def service_context
      { "service" => ENV["K_SERVICE"].presence || Rails.application.name, "version" => ENV["K_REVISION"].presence }.compact
    end

    # Rails puts the controller in the context of request errors; jobs have none.
    def event_context(error, context)
      request = context[:controller]&.request
      return unless request

      {
        "httpRequest" => http_request(request, error),
        "user" => (Current.user&.id&.to_s if defined?(Current))
      }.compact
    end

    def http_request(request, error)
      {
        "method" => request.request_method,
        # filtered_path hides filtered parameters (tokens, passwords) from the query string.
        "url" => "#{request.base_url}#{request.filtered_path}",
        "userAgent" => request.user_agent,
        "referrer" => request.referer,
        "responseStatusCode" => ActionDispatch::ExceptionWrapper.status_code_for_exception(error.class.name)
      }.compact
    end
end
