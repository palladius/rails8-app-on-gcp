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

  # Authored locally for bug reproduction (#243)
  test "requires email_address to be present" do
    [ nil, "", "   " ].each do |blank_email|
      user = User.new(email_address: blank_email, password: "password123", password_confirmation: "password123")
      assert_not user.valid?, "Expected #{blank_email.inspect} to be invalid"
      assert user.errors.of_kind?(:email_address, :blank), "Expected :blank error on :email_address for #{blank_email.inspect}"
      assert_equal [ "can't be blank" ], user.errors[:email_address]
    end
  end

  test "requires email_address to be unique case-insensitively and ignoring whitespace" do
    existing = users(:one)
    [ existing.email_address, " #{existing.email_address.upcase} ", " OnE@ExAmPlE.cOm " ].each do |dup_email|
      user = User.new(email_address: dup_email, password: "password123", password_confirmation: "password123")
      assert_not user.valid?, "Expected duplicate email #{dup_email.inspect} to be invalid"
      assert user.errors.of_kind?(:email_address, :taken), "Expected :taken error on :email_address for #{dup_email.inspect}"
      assert_includes user.errors[:email_address], "has already been taken"
    end
  end

  test "gravatar_url is nil-safe when email_address is nil" do
    user = User.new(email_address: nil)
    expected_hash = Digest::MD5.hexdigest("")
    assert_equal "https://www.gravatar.com/avatar/#{expected_hash}?s=80&d=retro", user.gravatar_url
  end
end
