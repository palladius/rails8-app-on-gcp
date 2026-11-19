# frozen_string_literal: true

# Authored locally for bug reproduction (Issue #197)
require "test_helper"

class ProductionMailerConfigTest < ActiveSupport::TestCase
  REPO_ROOT = Rails.root.join("..").expand_path

  PRODUCTION_CONFIG_FILES = [
    Rails.root.join("config/environments/production.rb"),
    REPO_ROOT.join("workshop/time-machine/stage-1-stateless/blog/config/environments/production.rb"),
    REPO_ROOT.join("workshop/time-machine/stage-2-gcs/blog/config/environments/production.rb")
  ].freeze

  test "disables mail delivery when no SMTP server is configured across production configs" do
    PRODUCTION_CONFIG_FILES.each do |path|
      cfg = evaluate_production_config(path, "SMTP_ADDRESS" => nil, "SMTP_HOST" => nil)
      assert_equal false, cfg.action_mailer.perform_deliveries,
                   "Expected #{path} to set perform_deliveries = false when SMTP is unconfigured"
    end
  end

  test "configures authenticated STARTTLS SMTP when SMTP_ADDRESS is provided" do
    env = {
      "SMTP_ADDRESS" => "smtp.example.com",
      "SMTP_HOST" => nil,
      "SMTP_PORT" => nil,
      "SMTP_USERNAME" => "apikey",
      "SMTP_PASSWORD" => "secret",
      "SMTP_AUTHENTICATION" => "plain",
      "SMTP_ENABLE_STARTTLS_AUTO" => nil
    }

    PRODUCTION_CONFIG_FILES.each do |path|
      cfg = evaluate_production_config(path, env)
      assert_equal :smtp, cfg.action_mailer.delivery_method, "Expected :smtp delivery_method in #{path}"
      refute_equal false, cfg.action_mailer.perform_deliveries, "Expected deliveries enabled in #{path}"
      assert_equal(
        {
          address: "smtp.example.com",
          port: 587,
          user_name: "apikey",
          password: "secret",
          authentication: :plain,
          enable_starttls_auto: true
        },
        cfg.action_mailer.smtp_settings,
        "Unexpected smtp_settings in #{path}"
      )
    end
  end

  test "supports unauthenticated SMTP_HOST relay such as local Mailpit" do
    env = {
      "SMTP_ADDRESS" => nil,
      "SMTP_HOST" => "mailpit",
      "SMTP_PORT" => "1025",
      "SMTP_USERNAME" => nil,
      "SMTP_PASSWORD" => nil,
      "SMTP_AUTHENTICATION" => nil,
      "SMTP_ENABLE_STARTTLS_AUTO" => "false"
    }

    PRODUCTION_CONFIG_FILES.each do |path|
      cfg = evaluate_production_config(path, env)
      assert_equal :smtp, cfg.action_mailer.delivery_method
      assert_equal "mailpit", cfg.action_mailer.smtp_settings[:address]
      assert_equal 1025, cfg.action_mailer.smtp_settings[:port]
      assert_equal false, cfg.action_mailer.smtp_settings[:enable_starttls_auto]
      refute cfg.action_mailer.smtp_settings.key?(:user_name), "Expected blank SMTP credentials to be omitted in #{path}"
    end
  end

  test "UserMailer welcome completes without ECONNREFUSED when perform_deliveries is false" do
    orig_perform = ActionMailer::Base.perform_deliveries
    orig_method = ActionMailer::Base.delivery_method
    orig_smtp = ActionMailer::Base.smtp_settings

    begin
      ActionMailer::Base.delivery_method = :smtp
      ActionMailer::Base.smtp_settings = { address: "127.0.0.1", port: 1 }
      ActionMailer::Base.perform_deliveries = false

      user = users(:one)
      assert_nothing_raised do
        UserMailer.with(user: user).welcome.deliver_now
      end
    ensure
      ActionMailer::Base.perform_deliveries = orig_perform
      ActionMailer::Base.delivery_method = orig_method
      ActionMailer::Base.smtp_settings = orig_smtp
    end
  end

  private

  def evaluate_production_config(path, env_overrides)
    keys = %w[
      SMTP_ADDRESS SMTP_HOST SMTP_PORT SMTP_USERNAME SMTP_PASSWORD
      SMTP_AUTHENTICATION SMTP_ENABLE_STARTTLS_AUTO LOG_FORMAT
      ACTIVE_STORAGE_SERVICE RAILS_LOG_LEVEL ALLOW_LOCAL_PROXY_CSRF
    ]
    saved_env = keys.to_h { |k| [ k, ENV[k] ] }

    env_overrides.each do |k, v|
      v.nil? ? ENV.delete(k) : ENV[k] = v
    end
    ENV["LOG_FORMAT"] = "plain"

    cfg = ActiveSupport::OrderedOptions.new
    %i[
      action_controller public_file_server active_storage active_support
      active_job solid_queue action_mailer i18n active_record
    ].each do |namespace|
      cfg[namespace] = ActiveSupport::OrderedOptions.new
    end

    fake_app = Object.new
    fake_app.define_singleton_method(:config) { cfg }
    fake_app.define_singleton_method(:credentials) do
      raise "production.rb must not evaluate Rails.application.credentials at boot (breaks SECRET_KEY_BASE_DUMMY=1)"
    end

    stub_singleton(Rails.application, :configure, ->(&block) { fake_app.instance_exec(&block) }) do
      eval(File.read(path), binding, path.to_s)
    end

    cfg
  ensure
    saved_env&.each do |k, v|
      v.nil? ? ENV.delete(k) : ENV[k] = v
    end
  end
end
