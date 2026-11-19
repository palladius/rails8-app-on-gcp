require "test_helper"
require "mail_delivery"

class MailDeliveryTest < ActiveSupport::TestCase
  setup do
    @config = ActiveSupport::OrderedOptions.new
  end

  test "without SMTP_HOST, deliveries are skipped so mail jobs complete" do
    MailDelivery.configure(@config, {})

    assert_equal false, @config.perform_deliveries
    assert_nil @config.delivery_method
    assert_nil @config.smtp_settings
  end

  test "without APP_HOST, links in mail use the placeholder host" do
    MailDelivery.configure(@config, {})

    assert_equal({ host: "example.com" }, @config.default_url_options)
  end

  test "APP_HOST sets the host used for links in mail" do
    MailDelivery.configure(@config, { "APP_HOST" => "blog.example.org" })

    assert_equal({ host: "blog.example.org" }, @config.default_url_options)
  end

  test "SMTP_HOST alone enables SMTP on port 587 without authentication" do
    MailDelivery.configure(@config, { "SMTP_HOST" => "smtp.example.org" })

    assert_equal true, @config.perform_deliveries
    assert_equal :smtp, @config.delivery_method
    assert_equal({ address: "smtp.example.org", port: 587 }, @config.smtp_settings)
  end

  test "SMTP_PORT, SMTP_USERNAME and SMTP_PASSWORD are passed on with plain authentication" do
    MailDelivery.configure(@config, {
      "SMTP_HOST" => "smtp.example.org",
      "SMTP_PORT" => "2525",
      "SMTP_USERNAME" => "mailer",
      "SMTP_PASSWORD" => "test-password"
    })

    assert_equal({
      address: "smtp.example.org",
      port: 2525,
      user_name: "mailer",
      password: "test-password",
      authentication: :plain
    }, @config.smtp_settings)
  end

  test "an empty SMTP_HOST counts as not configured" do
    MailDelivery.configure(@config, { "SMTP_HOST" => "" })

    assert_equal false, @config.perform_deliveries
  end
end
