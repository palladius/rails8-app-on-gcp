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

  def test_get_leaderboard_api_with_max_age
    env = Rack::MockRequest.env_for("/api/leaderboard?max_age=24h", method: "GET")
    status, headers, body = app.call(env)

    assert_equal 200, status
    body_str = ""
    body.each { |part| body_str += part }
    parsed = JSON.parse(body_str)

    assert_equal "ok", parsed["status"]
    assert_equal "24h", parsed["max_age"]
    assert parsed.key?("entries")
  end

  def test_get_healthchecks_api
    env = Rack::MockRequest.env_for("/api/healthchecks", method: "GET")
    status, headers, body = app.call(env)

    assert_equal 200, status
    assert_includes headers["content-type"], "application/json"

    body_str = ""
    body.each { |part| body_str += part }
    parsed = JSON.parse(body_str)

    assert parsed.is_a?(Hash)
    assert parsed.key?("checks")
    assert parsed.key?("timestamp")
  end

  def test_serves_index_html_with_table
    env = Rack::MockRequest.env_for("/", method: "GET")
    status, headers, body = app.call(env)

    assert_equal 200, status
    assert_includes headers["content-type"], "text/html"

    body_str = ""
    body.each { |part| body_str += part }
    assert_includes body_str, "Workshop Hive Leaderboard"
    assert_includes body_str, "leaderboard-tbody"
    assert_includes body_str, "/js/hive.js"
  end
end



