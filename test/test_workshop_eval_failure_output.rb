# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "yaml"
require "tmpdir"
require "fileutils"

# Issue #171: when a `shell` eval failed, the runner printed only stderr, so the minitest
# failure report (on stdout) never reached the attendee; and `just workshop-eval N` only
# worked from the repo root, while the codelab leaves attendees inside blog/.
class WorkshopEvalFailureOutputTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)

  def run_runner_with_shell_command(command)
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "bin"))
      FileUtils.mkdir_p(File.join(dir, "workshop"))
      FileUtils.cp(File.join(REPO_ROOT, "bin", "workshop_eval.rb"), File.join(dir, "bin"))
      FileUtils.cp_r(File.join(REPO_ROOT, "lib"), dir)
      File.write(File.join(dir, "workshop", "skeleton.yaml"), {
        "steps" => [{ "number" => 1, "title" => "Synthetic",
                      "evals" => [{ "id" => "sh", "type" => "shell", "description" => "Failing shell", "command" => command }] }]
      }.to_yaml)
      Open3.capture3("ruby", File.join(dir, "bin", "workshop_eval.rb"), "1")
    end
  end

  def test_failed_shell_eval_shows_stdout_and_stderr
    stdout, _stderr, status = run_runner_with_shell_command("echo OUT-$((40+2)); echo ERR-$((40+3)) >&2; exit 1")
    assert_equal 1, status.exitstatus
    assert_includes stdout, "OUT-42", "stdout of a failed check must be shown (minitest reports live there)"
    assert_includes stdout, "ERR-43"
  end

  def test_failed_shell_eval_shows_only_the_tail_of_long_output
    stdout, _stderr, _status = run_runner_with_shell_command("seq 1 200; exit 1")
    assert_match(/^\s*200$/, stdout)
    refute_match(/^\s*100$/, stdout, "only the last lines of a long output should be printed")
  end

  def test_failed_shell_eval_hides_multijson_deprecation_noise
    cmd = "for i in 1 2 3; do echo 'MultiJson constant is'' deprecated, use JSON'; done; echo REAL-$((1+1)); exit 1"
    stdout, _stderr, _status = run_runner_with_shell_command(cmd)
    assert_includes stdout, "REAL-2"
    refute_includes stdout, "MultiJson constant is deprecated"
    assert_includes stdout, "3 deprecation warning(s) hidden"
  end

  # The codelab leaves attendees in blog/ (`cd blog` in Steps 2, 3, 4, 6), and blog/ has its own justfile.
  def test_workshop_eval_works_from_the_blog_directory
    skip "just not installed" unless system("which just > /dev/null 2>&1")
    _out, err, status = Open3.capture3("just", "--dry-run", "workshop-eval", "6", chdir: File.join(REPO_ROOT, "blog"))
    assert status.success?, "`just workshop-eval 6` must work from blog/ (forwarding recipe): #{err}"
    assert_includes err, "workshop-eval 6"
  end
end
