# frozen_string_literal: true

require "minitest/autorun"
require "webrick"
require_relative "../lib/healthchecker"

class HealthcheckerTest < Minitest::Test
  def setup
    # Avviamo un piccolo server HTTP locale per simulare risposte UP e DOWN
    @port = 9876
    @server = WEBrick::HTTPServer.new(
      Port: @port,
      Logger: WEBrick::Log.new(File::NULL),
      AccessLog: []
    )

    @server.mount_proc "/up" do |req, res|
      res.status = 200
      res.body = "OK"
    end

    @server.mount_proc "/down" do |req, res|
      res.status = 500
      res.body = "Internal Server Error"
    end

    @thread = Thread.new { @server.start }
    sleep 0.1
  end

  def teardown
    @server.shutdown
    @thread.kill
  end

  def test_check_url_returns_up_on_200
    res = WorkshopHive::Healthchecker.check("http://127.0.0.1:#{@port}")
    assert_equal "up", res[:status]
    assert_equal 200, res[:http_code]
    assert res[:latency_ms] >= 0
  end

  def test_check_url_returns_down_on_server_error
    res = WorkshopHive::Healthchecker.check("http://127.0.0.1:#{@port}/down")
    assert_equal "down", res[:status]
    assert_equal 500, res[:http_code]
  end

  def test_check_url_returns_down_on_unreachable_host
    res = WorkshopHive::Healthchecker.check("http://127.0.0.1:1", timeout_seconds: 0.2)
    assert_equal "down", res[:status]
    refute_nil res[:error]
  end

  def test_check_batch_records_all_urls
    urls = [
      "http://127.0.0.1:#{@port}",
      "http://127.0.0.1:#{@port}/down"
    ]

    results = WorkshopHive::Healthchecker.check_all(urls)
    assert_equal 2, results.size
    assert_equal "up", results["http://127.0.0.1:#{@port}"][:status]
    assert_equal "down", results["http://127.0.0.1:#{@port}/down"][:status]
  end

  def test_check_url_parses_quest_telemetry_and_evaluates_proctor
    @server.mount_proc "/status.json" do |_req, res|
      res.status = 200
      res.content_type = "application/json"
      res.body = {
        system: { app_version: "0.2.12" },
        workshop_step: { number: 7, description: "Step 7: Generative AI Pipelines" },
        quest: {
          step_8_completed: true,
          ghi_issue: 83,
          ghi_url: "https://github.com/palladius/rails8-app-on-gcp/issues/83"
        }
      }.to_json
    end

    # Mock ProctorReviewer.review
    original_review = WorkshopHive::ProctorReviewer.method(:review)
    WorkshopHive::ProctorReviewer.define_singleton_method(:review) do |id|
      { status: :lgtm_approved, reviewer: "palladius", approved_at: "2026-09-10T12:00:00Z" }
    end

    begin
      res = WorkshopHive::Healthchecker.check("http://127.0.0.1:#{@port}")
      assert_equal "up", res[:status]
      t = res[:telemetry]
      assert_equal true, t[:quest_step_8_completed]
      assert_equal 83, t[:quest_ghi_issue]
      assert_equal "https://github.com/palladius/rails8-app-on-gcp/issues/83", t[:quest_ghi_url]
      assert_equal :lgtm_approved, t[:proctor_status]
      assert_equal "palladius", t[:proctor_reviewer]
      assert_equal 8, t[:step_number]
    ensure
      WorkshopHive::ProctorReviewer.define_singleton_method(:review, original_review)
    end
  end
end
