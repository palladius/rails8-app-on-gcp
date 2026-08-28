require "test_helper"

class IapAuthenticationTest < ActionDispatch::IntegrationTest
  test "auto-authenticates and creates user when IAP header is present" do
    assert_difference("User.count", 1) do
      get new_post_url, headers: { "X-Goog-Authenticated-User-Email" => "accounts.google.com:ricc@google.com" }
    end

    assert_response :success
    created_user = User.find_by(email_address: "ricc@google.com")
    assert_not_nil created_user
    assert cookies[:session_id]
  end

  test "auto-authenticates existing user when IAP header matches" do
    existing_user = users(:one)

    assert_no_difference("User.count") do
      get new_post_url, headers: { "X-Goog-Authenticated-User-Email" => existing_user.email_address }
    end

    assert_response :success
    assert cookies[:session_id]
  end

  test "redirects to login when no IAP header is present and unauthenticated" do
    get new_post_url
    assert_redirected_to new_session_url
  end

  test "respects IAP_MOCK_EMAIL in test environment" do
    ENV["IAP_MOCK_EMAIL"] = "emiliano.dellacasa@gmail.com"
    begin
      assert_difference("User.count", 1) do
        get new_post_url
      end
      assert_response :success
      assert_not_nil User.find_by(email_address: "emiliano.dellacasa@gmail.com")
    ensure
      ENV.delete("IAP_MOCK_EMAIL")
    end
  end
end
