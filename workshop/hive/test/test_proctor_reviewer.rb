# frozen_string_literal: true

require "minitest/autorun"
require "webrick"
require "json"
require_relative "../lib/proctor_reviewer"

class ProctorReviewerTest < Minitest::Test
  def setup
    WorkshopHive::ProctorReviewer.reset_cache!
    @port = 9877
    @comments_payload = []
    @http_status = 200
    @request_count = 0

    @server = WEBrick::HTTPServer.new(
      Port: @port,
      Logger: WEBrick::Log.new(File::NULL),
      AccessLog: []
    )

    @server.mount_proc "/repos/palladius/rails8-app-on-gcp/issues/83/comments" do |_req, res|
      @request_count += 1
      res.status = @http_status
      res.content_type = "application/json"
      res.body = @comments_payload.to_json
    end

    @thread = Thread.new { @server.start }
    sleep 0.1

    # Override base URL in test
    WorkshopHive::ProctorReviewer.github_api_base = "http://127.0.0.1:#{@port}"
    ENV["HIVE_PROCTORS"] = "palladius,emilianodellacasa,ricc"
  end

  def teardown
    @server.shutdown
    @thread.kill
    WorkshopHive::ProctorReviewer.github_api_base = nil
  end

  def test_lgtm_from_allowed_proctor_approves
    @comments_payload = [
      { "user" => { "login" => "student1" }, "body" => "I did this quest!" },
      { "user" => { "login" => "palladius" }, "body" => "Great work! LGTM 🚀" }
    ]

    res = WorkshopHive::ProctorReviewer.review(83)
    assert_equal :lgtm_approved, res[:status]
    assert_equal "palladius", res[:reviewer]
  end

  def test_lgtm_from_non_proctor_remains_pending
    @comments_payload = [
      { "user" => { "login" => "student1" }, "body" => "LGTM from myself!" }
    ]

    res = WorkshopHive::ProctorReviewer.review(83)
    assert_equal :review_pending, res[:status]
    assert_nil res[:reviewer]
  end

  def test_comment_from_proctor_without_lgtm_remains_pending
    @comments_payload = [
      { "user" => { "login" => "emilianodellacasa" }, "body" => "Please add tests before I approve" }
    ]

    res = WorkshopHive::ProctorReviewer.review(83)
    assert_equal :review_pending, res[:status]
    assert_nil res[:reviewer]
  end

  def test_github_api_error_falls_back_to_pending
    @http_status = 500
    res = WorkshopHive::ProctorReviewer.review(83)
    assert_equal :review_pending, res[:status]
  end

  def test_caching_avoids_repeated_network_calls
    @comments_payload = [
      { "user" => { "login" => "ricc" }, "body" => "Super awesome! lgtm" }
    ]

    res1 = WorkshopHive::ProctorReviewer.review(83)
    assert_equal :lgtm_approved, res1[:status]
    assert_equal 1, @request_count

    # Second call should read from in-memory cache
    res2 = WorkshopHive::ProctorReviewer.review(83)
    assert_equal :lgtm_approved, res2[:status]
    assert_equal 1, @request_count
  end
end
