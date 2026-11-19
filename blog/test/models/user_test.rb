require "test_helper"

class UserTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "delivers password reset email" do
    user = users(:one)
    assert_emails 1 do
      PasswordsMailer.reset(user).deliver_now
    end
  end

  test "admin? is true only for the account db/seeds.rb creates from GOOGLE_CLOUD_ACCOUNT" do
    with_admin_env("GOOGLE_CLOUD_ACCOUNT" => " One@Example.com ") do
      assert users(:one).admin?
      assert_not users(:two).admin?
    end
  end

  test "admin? falls back to ADMIN_EMAIL like db/seeds.rb" do
    with_admin_env("ADMIN_EMAIL" => "two@example.com") do
      assert users(:two).admin?
      assert_not users(:one).admin?
    end
  end

  test "nobody is admin when no admin email is configured" do
    with_admin_env({}) do
      assert_not users(:one).admin?
      assert_not User.new.admin?
    end
  end

  private
    ADMIN_ENV_KEYS = %w[GOOGLE_CLOUD_ACCOUNT GOOGLE_CLOUD_EMAIL ADMIN_EMAIL].freeze

    def with_admin_env(values)
      saved = ADMIN_ENV_KEYS.to_h { |key| [ key, ENV[key] ] }
      ADMIN_ENV_KEYS.each { |key| ENV.delete(key) }
      values.each { |key, value| ENV[key] = value }
      yield
    ensure
      saved.each { |key, value| ENV[key] = value }
    end
end
