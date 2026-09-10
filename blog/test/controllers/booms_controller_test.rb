require "test_helper"

class BoomsControllerTest < ActionDispatch::IntegrationTest
  test "GET /boom triggers deliberate RuntimeError for Error Reporting verification" do
    # In test environment with show_exceptions, verify it raises or outputs to stderr
    captured_stderr = StringIO.new
    original_stderr = $stderr
    $stderr = captured_stderr

    begin
      assert_raises(RuntimeError) do
        get "/boom"
      end
    ensure
      $stderr = original_stderr
    end

    # Stderr should contain exception details formatted for Cloud Error Reporting
    assert_match(/💥 Deliberate Boom/i, captured_stderr.string)
  end

  test "GET /boom in production mode returns 500 and renders error" do
    # Test production error handling with rescue_from / show_exceptions
    Rails.application.env_config["action_dispatch.show_exceptions"] = :all
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = false

    captured_stderr = StringIO.new
    original_stderr = $stderr
    $stderr = captured_stderr

    begin
      get "/boom"
      assert_response :internal_server_error
    ensure
      $stderr = original_stderr
      Rails.application.env_config["action_dispatch.show_exceptions"] = :none
      Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = true
    end

    assert_match(/💥 Deliberate Boom/i, captured_stderr.string)
  end
end
