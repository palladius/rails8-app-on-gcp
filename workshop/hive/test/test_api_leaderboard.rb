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

  def test_get_leaderboard_api_deduplicates_duplicate_urls
    original_raw = WorkshopHive::SheetsReader.method(:get_raw_entries)
    WorkshopHive::SheetsReader.define_singleton_method(:get_raw_entries) do |**_args|
      [
        { nickname: "First", url: "https://dupe.run.app/", timestamp: "11:00" },
        { nickname: "Unique", url: "https://unique.run.app/", timestamp: "11:05" },
        { nickname: "Second", url: "https://dupe.run.app", timestamp: "11:10" }
      ]
    end

    begin
      env = Rack::MockRequest.env_for("/api/leaderboard", method: "GET")
      status, _headers, body = app.call(env)

      assert_equal 200, status
      body_str = ""
      body.each { |part| body_str += part }
      parsed = JSON.parse(body_str)

      assert_equal 2, parsed["total_students"]
      assert_equal 2, parsed["entries"].size
      assert_equal "Unique", parsed["entries"][0]["nickname"]
      assert_equal "Second", parsed["entries"][1]["nickname"]
      assert_equal "11:10", parsed["entries"][1]["timestamp"]
    ensure
      WorkshopHive::SheetsReader.define_singleton_method(:get_raw_entries, original_raw)
    end
  end

  def test_get_leaderboard_api_shows_duplicates_when_requested
    original_raw = WorkshopHive::SheetsReader.method(:get_raw_entries)
    WorkshopHive::SheetsReader.define_singleton_method(:get_raw_entries) do |**_args|
      [
        { nickname: "First", url: "https://dupe.run.app/", timestamp: "11:00" },
        { nickname: "Unique", url: "https://unique.run.app/", timestamp: "11:05" },
        { nickname: "Second", url: "https://dupe.run.app", timestamp: "11:10" }
      ]
    end

    begin
      # Standard show_duplicates=true
      env1 = Rack::MockRequest.env_for("/api/leaderboard?show_duplicates=true", method: "GET")
      _, _, body1 = app.call(env1)
      parsed1 = JSON.parse(body1.join)
      assert_equal true, parsed1["show_duplicates"]
      assert_equal 3, parsed1["total_students"]
      assert_equal 3, parsed1["entries"].size
      assert_equal ["First", "Unique", "Second"], parsed1["entries"].map { |e| e["nickname"] }

      # Typo-tolerant show_duplicatees_true
      env2 = Rack::MockRequest.env_for("/api/leaderboard?show_duplicatees_true", method: "GET")
      _, _, body2 = app.call(env2)
      parsed2 = JSON.parse(body2.join)
      assert_equal true, parsed2["show_duplicates"]
      assert_equal 3, parsed2["total_students"]
    ensure
      WorkshopHive::SheetsReader.define_singleton_method(:get_raw_entries, original_raw)
    end
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



