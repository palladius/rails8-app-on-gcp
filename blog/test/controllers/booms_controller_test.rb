require "test_helper"

class BoomsControllerTest < ActionDispatch::IntegrationTest
  test "GET /boom raises a deliberate RuntimeError for Error Reporting verification" do
    assert_raises(RuntimeError, match: /💥 Deliberate Boom/) do
      get "/boom"
    end
  end

  test "GET /boom in production mode returns 500 and renders error" do
    Rails.application.env_config["action_dispatch.show_exceptions"] = :all
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = false

    get "/boom"
    assert_response :internal_server_error
  ensure
    Rails.application.env_config["action_dispatch.show_exceptions"] = :none
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = true
  end
end
