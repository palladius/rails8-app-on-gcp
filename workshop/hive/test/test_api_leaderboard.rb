# frozen_string_literal: true

require "minitest/autorun"
require "rack"
require_relative "../app"

class AppLeaderboardApiTest < Minitest::Test
  def app
    WorkshopHive::App.new
  end

  def test_get_up_endpoint
    env = Rack::MockRequest.env_for("/up", method: "GET")
    status, headers, body = app.call(env)

    assert_equal 200, status
    assert_includes headers["content-type"], "application/json"

    body_str = ""
    body.each { |part| body_str += part }
    parsed = JSON.parse(body_str)
    assert_equal "ok", parsed["status"]
    assert_equal "workshop-hive", parsed["service"]
  end

  def test_get_leaderboard_api
    env = Rack::MockRequest.env_for("/api/leaderboard", method: "GET")
    status, headers, body = app.call(env)

    assert_equal 200, status
    assert_includes headers["content-type"], "application/json"

    body_str = ""
    body.each { |part| body_str += part }
    parsed = JSON.parse(body_str)

    assert parsed.is_a?(Hash)
    assert parsed.key?("entries")
    assert parsed.key?("total_students")
    assert parsed["entries"].is_a?(Array)
    refute_empty parsed["entries"]
  end
end
