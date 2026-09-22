# frozen_string_literal: true

require "minitest/autorun"
require_relative "../workshop/telemetry/friction_log"
require_relative "../workshop/bin/verify_fl_concurrency"

class FrictionLogConcurrencyUatTest < Minitest::Test
  def setup
    yaml_path = File.expand_path("../workshop/telemetry/friction_logs.yaml", __dir__)
    logs = FrictionLog.load_all(yaml_path)
    @fl06 = logs.find { |l| l.id == "FL006" }
    @fl07 = logs.find { |l| l.id == "FL007" }
  end

  def test_fl06_and_fl07_presence
    refute_nil @fl06, "FL006 must exist in telemetry"
    refute_nil @fl07, "FL007 must exist in telemetry"
  end

  def test_shared_ancestor_commit_baseline
    assert_equal @fl06.code_commit_sha, @fl07.code_commit_sha,
                 "UAT Invariant: FL006 and FL007 must start from the identical code commit baseline"
    assert_equal "4a2f81a", @fl06.code_commit_sha

    assert_equal @fl06.workshop_commit_sha, @fl07.workshop_commit_sha,
                 "UAT Invariant: FL006 and FL007 must share the identical workshop curriculum commit"
    assert_equal "8d1b32e", @fl06.workshop_commit_sha
  end

  def test_temporal_overlap
    overlap_result = FrictionLogConcurrencyVerifier.calculate_overlap(@fl06, @fl07)

    assert overlap_result[:concurrent], "FL006 and FL007 must execute concurrently"
    assert overlap_result[:overlap_seconds] > 400_000, "Overlap must cover the multi-day run window"
    assert overlap_result[:overlap_percentage] > 95.0, "Temporal concurrency overlap must exceed 95%"
  end

  def test_parallel_pr_generation
    report = FrictionLogConcurrencyVerifier.analyze_parallel_prs(@fl06, @fl07)

    assert_equal 3, report[:fl06_prs].size
    assert_equal 2, report[:fl07_prs].size

    # Verify key PRs are tracked
    assert_includes report[:fl06_prs].join, "113"
    assert_includes report[:fl07_prs].join, "133"
  end

  def test_concurrency_verifier_report
    report_text = FrictionLogConcurrencyVerifier.generate_report(@fl06, @fl07)
    assert_includes report_text, "CONCURRENCY UAT: PASS"
    assert_includes report_text, "FL006"
    assert_includes report_text, "FL007"
    assert_includes report_text, "4a2f81a"
  end
end
