require "test_helper"

class IapAuthenticationTest < ActionDispatch::IntegrationTest
  test "auto-authenticates and creates user when IAP header is present" do
    assert_difference("User.count", 1) do
      get new_post_url, headers: { "X-Goog-Authenticated-User-Email" => "accounts.google.com:ricc@google.com" }
    end

    assert_response :success
    created_user = User.find_by(email_address: "ricc@google.com")
    assert_not_nil created_user
    assert_equal "iap", created_user.created_via
    assert_equal "Auto-generated as logged in from IAP allow listed users", created_user.description
    assert cookies[:session_id]

    assert_includes response.body, "Login recognized by IAP -&gt; User ##{created_user.id} (#{created_user.email_address}) just created!"
  end


  test "auto-authenticates existing user when IAP header matches" do
    existing_user = users(:one)

    assert_no_difference("User.count") do
      get new_post_url, headers: { "X-Goog-Authenticated-User-Email" => existing_user.email_address }
    end

    assert_response :success
    assert cookies[:session_id]
    assert_includes response.body, "Login recognized by IAP -&gt; User ##{existing_user.id} (#{existing_user.email_address})"
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

  test "blocks IAP user not in IAP_ALLOWED_USERS" do
    ENV["IAP_ALLOWED_USERS"] = "ricc@google.com,palladiusbonton@gmail.com"
    begin
      assert_no_difference("User.count") do
        get new_post_url, headers: { "X-Goog-Authenticated-User-Email" => "accounts.google.com:unauthorized@example.com" }
      end
      assert_redirected_to new_session_url
    ensure
      ENV.delete("IAP_ALLOWED_USERS")
    end
  end

  test "allows IAP user in IAP_ALLOWED_USERS" do
    ENV["IAP_ALLOWED_USERS"] = "ricc@google.com,palladiusbonton@gmail.com,riccardo.and.kate@gmail.com,riccardo.carlesso@gmail.com"
    begin
      assert_difference("User.count", 1) do
        get new_post_url, headers: { "X-Goog-Authenticated-User-Email" => "accounts.google.com:riccardo.carlesso@gmail.com" }
      end
      assert_response :success
      assert_not_nil User.find_by(email_address: "riccardo.carlesso@gmail.com")
    ensure
      ENV.delete("IAP_ALLOWED_USERS")
    end
  end
end

