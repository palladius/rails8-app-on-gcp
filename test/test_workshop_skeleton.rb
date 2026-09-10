require "minitest/autorun"
require "yaml"

class WorkshopSkeletonTest < Minitest::Test
  SKELETON_PATH = File.expand_path("../workshop/skeleton.yaml", __dir__)

  def setup
    @skeleton = YAML.load_file(SKELETON_PATH)
  end

  def test_skeleton_file_loads
    refute_nil @skeleton
    assert @skeleton.key?("steps")
    assert_kind_of Array, @skeleton["steps"]
  end

  def test_steps_support_declarative_screenshots
    steps_with_screenshots = @skeleton["steps"].select { |s| s["screenshots"] }
    refute_empty steps_with_screenshots, "Expected at least one step with declarative screenshots in skeleton.yaml"

    step = steps_with_screenshots.first
    screenshot = step["screenshots"].first
    assert screenshot["id"], "Screenshot missing 'id'"
    assert screenshot["title"], "Screenshot missing 'title'"
    assert screenshot["output_path"], "Screenshot missing 'output_path'"
    assert screenshot["script"], "Screenshot missing 'script'"
  end

  def test_skeleton_declares_cumulative_invariants
    assert @skeleton.key?("invariants"), "skeleton.yaml must declare root-level 'invariants' list"
    assert_kind_of Array, @skeleton["invariants"]
    refute_empty @skeleton["invariants"], "Expected at least one invariant declared in skeleton.yaml"

    @skeleton["invariants"].each do |inv|
      assert inv["id"], "Invariant missing 'id'"
      assert inv["from_step"], "Invariant '#{inv['id']}' missing 'from_step'"
      assert_kind_of Integer, inv["from_step"], "Invariant 'from_step' must be an integer"
      assert inv["title"], "Invariant '#{inv['id']}' missing 'title'"
      assert inv["description"], "Invariant '#{inv['id']}' missing 'description'"
      assert inv["check"], "Invariant '#{inv['id']}' missing 'check'"
    end

    invariant_ids = @skeleton["invariants"].map { |i| i["id"] }
    assert_includes invariant_ids, "inv-persistent-gcs-storage"
    assert_includes invariant_ids, "inv-zero-stuck-background-jobs"
    assert_includes invariant_ids, "inv-cloud-sql-connected"
  end

  def test_steps_include_status_json_inference_evals
    [5, 6, 7].each do |step_num|
      step = @skeleton["steps"].find { |s| s["number"] == step_num }
      refute_nil step, "Step #{step_num} missing in skeleton.yaml"
      eval_ids = (step["evals"] || []).map { |e| e["id"] }
      assert_includes eval_ids, "step-#{step_num}-ruby-status-json-step",
                      "Step #{step_num} must include status telemetry inference eval"
    end
  end
end
