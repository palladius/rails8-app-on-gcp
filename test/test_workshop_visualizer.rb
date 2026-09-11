# frozen_string_literal: true

require "minitest/autorun"
require "rack/mock_request"

# Require the Sinatra server
require_relative "../workshop/visualizer/server"

class WorkshopVisualizerTest < Minitest::Test
  def setup
    @app = CodelabServer.new
    @request = Rack::MockRequest.new(@app)
    # Ensure clean ENV and CLI_OPTIONS before each test
    @original_env_debug = ENV["DEBUG"]
    ENV.delete("DEBUG")
    CLI_OPTIONS[:debug] = false
  end

  def teardown
    if @original_env_debug.nil?
      ENV.delete("DEBUG")
    else
      ENV["DEBUG"] = @original_env_debug
    end
    CLI_OPTIONS[:debug] = false
  end

  def test_codelab_without_debug_hides_constitution_and_skeleton_links
    res = @request.get("/codelab")
    assert_equal 200, res.status
    refute_includes res.body, 'href="/constitution"'
    refute_includes res.body, 'href="/skeleton"'
    assert_includes res.body, 'href="/codelab"'
  end

  def test_codelab_with_query_param_debug_shows_constitution_and_skeleton_links
    res = @request.get("/codelab?debug=1")
    assert_equal 200, res.status
    assert_includes res.body, 'href="/constitution"'
    assert_includes res.body, 'href="/skeleton"'
    assert_includes res.body, 'href="/codelab"'

    # Check that cookie was set to remember debug mode
    cookie_header = res.headers["set-cookie"] || res.headers["Set-Cookie"]
    refute_nil cookie_header, "Set-Cookie should be present when toggling debug mode"
    assert_includes cookie_header.to_s, "codelab_debug=1"
  end

  def test_codelab_with_query_param_debug_true_shows_links
    res = @request.get("/codelab?debug=true")
    assert_equal 200, res.status
    assert_includes res.body, 'href="/constitution"'
    assert_includes res.body, 'href="/skeleton"'
  end

  def test_codelab_with_cookie_persists_debug_mode
    res = @request.get("/codelab", "HTTP_COOKIE" => "codelab_debug=1")
    assert_equal 200, res.status
    assert_includes res.body, 'href="/constitution"'
    assert_includes res.body, 'href="/skeleton"'
  end

  def test_codelab_with_query_param_debug_zero_disables_debug_mode
    res = @request.get("/codelab?debug=0", "HTTP_COOKIE" => "codelab_debug=1")
    assert_equal 200, res.status
    refute_includes res.body, 'href="/constitution"'
    refute_includes res.body, 'href="/skeleton"'
    cookie_header = res.headers["set-cookie"] || res.headers["Set-Cookie"]
    assert_includes cookie_header.to_s, "codelab_debug=0"
  end

  def test_codelab_with_env_debug_shows_links
    ENV["DEBUG"] = "1"
    res = @request.get("/codelab")
    assert_equal 200, res.status
    assert_includes res.body, 'href="/constitution"'
    assert_includes res.body, 'href="/skeleton"'
  end

  def test_codelab_with_cli_flag_debug_shows_links
    CLI_OPTIONS[:debug] = true
    res = @request.get("/codelab")
    assert_equal 200, res.status
    assert_includes res.body, 'href="/constitution"'
    assert_includes res.body, 'href="/skeleton"'
  end

  def test_constitution_page_always_shows_navigation_tabs
    res = @request.get("/constitution")
    assert_equal 200, res.status
    assert_includes res.body, 'href="/codelab"'
    assert_includes res.body, 'href="/constitution"'
    assert_includes res.body, 'href="/skeleton"'
  end

  def test_skeleton_page_always_shows_navigation_tabs
    res = @request.get("/skeleton")
    assert_equal 200, res.status
    assert_includes res.body, 'href="/codelab"'
    assert_includes res.body, 'href="/constitution"'
    assert_includes res.body, 'href="/skeleton"'
  end

  def test_workshop_alias_without_debug_hides_constitution_and_skeleton_links
    res = @request.get("/workshop/")
    assert_equal 200, res.status
    refute_includes res.body, 'href="/constitution"'
    refute_includes res.body, 'href="/skeleton"'
  end
end
