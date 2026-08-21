require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should create user and send welcome email" do
    assert_difference("User.count") do
      assert_enqueued_emails 1 do
        post signup_path, params: {
          user: {
            email_address: "new_user_#{Time.now.to_i}@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end
    end

    assert_redirected_to root_path
    assert_equal "Welcome aboard! 🎉 Account created successfully.", flash[:notice]
  end
end
