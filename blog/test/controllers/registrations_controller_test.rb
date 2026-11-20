require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should create user and send welcome email" do
    assert_difference("User.count") do
      assert_enqueued_emails 1 do
        post registration_path, params: {
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

  # Authored locally for bug reproduction (#243)
  test "should reject duplicate email with 422 instead of raising RecordNotUnique" do
    existing = users(:one)
    [ existing.email_address, " #{existing.email_address.upcase} ", " OnE@ExAmPlE.cOm " ].each do |dup_email|
      assert_no_difference([ "User.count", "Session.count" ]) do
        assert_no_enqueued_emails do
          post registration_path, params: {
            user: {
              email_address: dup_email,
              password: "password123",
              password_confirmation: "password123"
            }
          }
        end
      end

      assert_response :unprocessable_content
      assert_match(/already been taken/i, response.body)
      assert_nil cookies[:session_id]
    end
  end

  test "should reject nil, empty, and whitespace-only email with 422" do
    [
      { password: "password123", password_confirmation: "password123" },
      { email_address: "", password: "password123", password_confirmation: "password123" },
      { email_address: "   ", password: "password123", password_confirmation: "password123" }
    ].each do |user_params|
      assert_no_difference([ "User.count", "Session.count" ]) do
        assert_no_enqueued_emails do
          post registration_path, params: { user: user_params }
        end
      end

      assert_response :unprocessable_content
      assert_match(/can(?:'|&#39;)t be blank/i, response.body)
      assert_nil cookies[:session_id]
    end
  end

  test "should handle concurrent RecordNotUnique race with 422" do
    race_user = User.new(
      email_address: "race@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    race_user.define_singleton_method(:save) { raise ActiveRecord::RecordNotUnique, "duplicate key" }

    stub_singleton(User, :new, ->(*_args) { race_user }) do
      assert_no_difference([ "User.count", "Session.count" ]) do
        assert_no_enqueued_emails do
          post registration_path, params: {
            user: {
              email_address: "race@example.com",
              password: "password123",
              password_confirmation: "password123"
            }
          }
        end
      end
    end

    assert_response :unprocessable_content
    assert_match(/already been taken/i, response.body)
    assert_nil cookies[:session_id]
  end

  test "does not rescue RecordNotUnique raised outside user.save" do
    downstream_user = User.new(
      email_address: "downstream@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    downstream_user.define_singleton_method(:sessions) do
      raise ActiveRecord::RecordNotUnique, "unrelated unique index violation"
    end

    stub_singleton(User, :new, ->(*_args) { downstream_user }) do
      assert_raises(ActiveRecord::RecordNotUnique) do
        post registration_path, params: {
          user: {
            email_address: "downstream@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end
    end
  end
end
