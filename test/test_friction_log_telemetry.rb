# frozen_string_literal: true

require "minitest/autorun"
require_relative "../workshop/telemetry/friction_log"

class FrictionLogTelemetryTest < Minitest::Test
  def setup
    @sample_fl_hash = {
      "id" => "FL006",
      "title" => "Step 0-8 Full Workshop & URI Parser Workarounds",
      "runner" => "antigravity-bot",
      "account" => "rubycon.italy@gmail.com",
      "gcp_project_id" => "rails8-fl006-20260911",
      "ghi_url" => "https://github.com/palladius/rails8-app-on-gcp/issues/95",
      "pr_urls" => [
        "https://github.com/palladius/rails8-app-on-gcp/pull/99",
        "https://github.com/palladius/rails8-app-on-gcp/pull/109",
        "https://github.com/palladius/rails8-app-on-gcp/pull/113"
      ],
      "started_at" => "2026-09-11T14:00:00Z",
      "ended_at" => "2026-09-16T09:46:00Z",
      "pauses" => [
        {
          "started_at" => "2026-09-11T17:30:00Z",
          "resumed_at" => "2026-09-16T09:00:00Z",
          "reason" => "Interrupted over weekend / Thu-Fri pause; resumed Monday morning"
        }
      ],
      "active_duration_seconds" => 10800, # 3 hours
      "wall_clock_duration_seconds" => 416760, # ~115 hours
      "code_commit" => {
        "sha" => "4a2f81a",
        "pushed_at" => "2026-09-11T14:15:00Z"
      },
      "workshop_commit" => {
        "sha" => "8d1b32e",
        "pushed_at" => "2026-09-11T14:20:00Z"
      },
      "eval_score" => "69/69 ✅",
      "bugs_found_count" => 20,
      "status" => "success",
      "steps" => {
        0 => { "status" => "completed", "duration_seconds" => 83, "errors_count" => 0, "warnings_count" => 0 },
        1 => { "status" => "completed", "duration_seconds" => 900, "errors_count" => 0, "warnings_count" => 0 },
        2 => { "status" => "completed", "duration_seconds" => 300, "errors_count" => 0, "warnings_count" => 1 },
        3 => { "status" => "completed", "duration_seconds" => 600, "errors_count" => 2, "warnings_count" => 0 },
        4 => { "status" => "completed", "duration_seconds" => 600, "errors_count" => 1, "warnings_count" => 0 },
        5 => { "status" => "completed", "duration_seconds" => 3600, "errors_count" => 6, "warnings_count" => 1 },
        6 => { "status" => "completed", "duration_seconds" => 3600, "errors_count" => 8, "warnings_count" => 0 },
        7 => { "status" => "completed", "duration_seconds" => 600, "errors_count" => 2, "warnings_count" => 0 },
        8 => { "status" => "completed", "duration_seconds" => 517, "errors_count" => 1, "warnings_count" => 0 }
      }
    }
  end

  def test_initialization_and_attributes
    fl = FrictionLog.new(@sample_fl_hash)
    assert_equal "FL006", fl.id
    assert_equal "Step 0-8 Full Workshop & URI Parser Workarounds", fl.title
    assert_equal "rails8-fl006-20260911", fl.gcp_project_id
    assert_equal "69/69 ✅", fl.eval_score
    assert_equal 20, fl.bugs_found_count
  end

  def test_pause_calculations
    fl = FrictionLog.new(@sample_fl_hash)
    assert_equal 1, fl.pauses.size
    pause = fl.pauses.first
    assert_equal "Interrupted over weekend / Thu-Fri pause; resumed Monday morning", pause["reason"]
    assert fl.paused?
    assert fl.pause_duration_seconds > 0
    assert_equal fl.wall_clock_duration_seconds - fl.pause_duration_seconds, fl.calculated_active_duration_seconds
  end

  def test_step_metrics
    fl = FrictionLog.new(@sample_fl_hash)
    assert_equal 9, fl.steps.size # Steps 0..8
    assert_equal 83, fl.step(0)["duration_seconds"]
    assert_equal 6, fl.step(5)["errors_count"]
    assert_equal 20, fl.total_step_errors
    assert_equal 2, fl.total_step_warnings
  end

  def test_git_provenance
    fl = FrictionLog.new(@sample_fl_hash)
    assert_equal "4a2f81a", fl.code_commit_sha
    assert_equal "8d1b32e", fl.workshop_commit_sha
    assert_equal "2026-09-11T14:15:00Z", fl.code_commit_pushed_at
    assert_equal "2026-09-11T14:20:00Z", fl.workshop_commit_pushed_at
  end

  def test_validation_success
    fl = FrictionLog.new(@sample_fl_hash)
    assert fl.valid?, "Expected friction log to be valid: #{fl.errors.join(', ')}"
  end

  def test_validation_catches_invalid_dates
    invalid_hash = @sample_fl_hash.merge("started_at" => "not-a-date")
    fl = FrictionLog.new(invalid_hash)
    refute fl.valid?
    assert_includes fl.errors.join, "started_at must be valid ISO8601"
  end

  def test_validation_catches_wall_clock_less_than_active
    invalid_hash = @sample_fl_hash.merge(
      "wall_clock_duration_seconds" => 100,
      "active_duration_seconds" => 200
    )
    fl = FrictionLog.new(invalid_hash)
    refute fl.valid?
    assert_includes fl.errors.join, "wall_clock_duration cannot be less than active_duration"
  end

  def test_collection_loader
    yaml_path = File.expand_path("../workshop/telemetry/friction_logs.yaml", __dir__)
    logs = FrictionLog.load_all(yaml_path)
    assert_kind_of Array, logs
    assert_equal 8, logs.size # FL000 through FL007
    assert logs.all?(&:valid?)
  end
end
