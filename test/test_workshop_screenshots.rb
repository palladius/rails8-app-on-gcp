require "minitest/autorun"
require "open3"
require "yaml"
require "json"
require "fileutils"

class WorkshopScreenshotsTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)
  RUNNER_PATH = File.join(REPO_ROOT, "workshop/screenshots/runner.js")
  SKELETON_PATH = File.join(REPO_ROOT, "workshop/skeleton.yaml")

  def test_runner_file_exists_and_executable
    assert File.exist?(RUNNER_PATH), "Expected runner.js to exist at #{RUNNER_PATH}"
  end

  def test_runner_list_command_outputs_json
    stdout, stderr, status = Open3.capture3("node", RUNNER_PATH, "--list", chdir: REPO_ROOT)
    assert_equal 0, status.exitstatus, "Runner --list failed: #{stderr}"
    data = JSON.parse(stdout)
    assert_kind_of Array, data
    refute_empty data
    assert data.any? { |s| s["id"] == "step-2-home-ephemeral" }
  end

  def test_all_declared_scripts_exist_on_filesystem
    skeleton = YAML.load_file(SKELETON_PATH)
    screenshots = skeleton["steps"].flat_map { |s| s["screenshots"] || [] }
    refute_empty screenshots

    screenshots.each do |shot|
      script_path = File.join(REPO_ROOT, shot["script"])
      assert File.exist?(script_path), "Script #{shot['script']} declared in skeleton.yaml but missing on disk!"
    end
  end
end
