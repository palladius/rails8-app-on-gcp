require "test_helper"

class MissingAdminWarningTest < ActionDispatch::IntegrationTest
  test "renders missing admin warning when User count is 0" do
    User.delete_all

    get posts_url
    assert_response :success
    assert_select ".workshop-missing-admin-alert" do
      assert_select "strong", text: /No administrator user found in database!/
      assert_select "a", text: /Why\? \(Ask AI\)/
    end
  end

  test "does not render missing admin warning when users exist" do
    User.create!(email_address: "admin@example.com", password: "password123")

    get posts_url
    assert_response :success
    assert_select ".workshop-missing-admin-alert", count: 0
  end

  test "suppresses alerts when DISABLE_WORKSHOP_ALERTS is true" do
    User.delete_all

    with_env("DISABLE_WORKSHOP_ALERTS" => "true") do
      get posts_url
      assert_response :success
      assert_select ".workshop-alerts-hub", count: 0
      assert_select ".workshop-missing-admin-alert", count: 0
    end
  end

  private

  def with_env(env_hash)
    orig_env = {}
    env_hash.each do |k, v|
      orig_env[k] = ENV[k]
      ENV[k] = v
    end
    yield
  ensure
    orig_env.each do |k, v|
      ENV[k] = v
    end
  end
end
