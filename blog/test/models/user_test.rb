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
end
