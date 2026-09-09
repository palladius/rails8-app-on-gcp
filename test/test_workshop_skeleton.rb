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
end
