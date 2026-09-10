# frozen_string_literal: true

require "minitest/autorun"
require "yaml"
require_relative "../lib/workshop_eval/invariant_checker"

class WorkshopInvariantsTest < Minitest::Test
  SKELETON_PATH = File.expand_path("../workshop/skeleton.yaml", __dir__)

  def setup
    @skeleton = YAML.load_file(SKELETON_PATH)
    @invariants = @skeleton["invariants"] || []
    @checker = WorkshopEval::InvariantChecker.new(invariants: @invariants, repo_root: File.expand_path("..", __dir__))
  end

  def test_filters_invariants_by_step
    inv_step_3 = @checker.invariants_for_step(3)
    assert_empty inv_step_3.select { |i| i["from_step"] > 3 }, "Step 3 should not include invariants from Step 4+"

    inv_step_4 = @checker.invariants_for_step(4)
    refute_empty inv_step_4.select { |i| i["id"] == "inv-persistent-gcs-storage" }
    assert_empty inv_step_4.select { |i| i["from_step"] > 4 }, "Step 4 should not include invariants from Step 6+"

    inv_step_7 = @checker.invariants_for_step(7)
    step_7_ids = inv_step_7.map { |i| i["id"] }
    assert_includes step_7_ids, "inv-persistent-gcs-storage"
    assert_includes step_7_ids, "inv-zero-stuck-background-jobs"
    assert_includes step_7_ids, "inv-cloud-sql-connected"
  end

  def test_check_compose_has_service_passes_when_service_present
    inv = {
      "id" => "test-compose",
      "check" => "compose_has_service",
      "params" => { "service" => "cloudsql-proxy", "file" => "blog/compose.prod.yaml" }
    }
    result = @checker.evaluate_invariant(inv)
    assert result[:passed], "Expected compose_has_service to pass for cloudsql-proxy in compose.prod.yaml"
  end

  def test_check_compose_has_service_fails_when_service_missing
    inv = {
      "id" => "test-compose-fail",
      "check" => "compose_has_service",
      "params" => { "service" => "nonexistent-sidecar-service-xyz", "file" => "blog/compose.prod.yaml" }
    }
    result = @checker.evaluate_invariant(inv)
    refute result[:passed]
    assert_match(/nonexistent-sidecar-service-xyz/, result[:error_message])
  end

  def test_check_no_local_storage_detects_storage_configuration
    inv = {
      "id" => "test-storage",
      "check" => "no_local_storage",
      "params" => { "config_file" => "blog/config/storage.yml" }
    }
    result = @checker.evaluate_invariant(inv)
    assert result[:passed]
  end

  def test_check_zero_stuck_jobs_runs_safely
    inv = {
      "id" => "test-jobs",
      "check" => "zero_stuck_jobs"
    }
    result = @checker.evaluate_invariant(inv)
    # In test/local environment without running Solid Queue worker or pending jobs, it must pass without crashing
    assert result[:passed], "zero_stuck_jobs should pass when queue is clean or idle: #{result[:error_message]}"
  end
end
