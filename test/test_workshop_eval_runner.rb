# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "yaml"
require "tmpdir"
require "fileutils"

# Issue #166: `just workshop-eval 5` crashed with `LoadError: cannot infer basepath`
# because a skeleton.yaml `ruby` eval used `require_relative` / `__dir__` inside
# `eval`, and the runner only rescued StandardError (LoadError is a ScriptError).
class WorkshopEvalRunnerTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)
  SKELETON = File.join(REPO_ROOT, "workshop", "skeleton.yaml")

  def ruby_evals
    steps = YAML.load_file(SKELETON)["steps"] || []
    steps.flat_map { |s| (s["evals"] || []).select { |e| e["type"] == "ruby" } }
  end

  # The runner `eval`s these strings from bin/workshop_eval.rb after chdir to the repo
  # root: `require_relative` has no base path and `__dir__` / `__FILE__` are nil/odd there.
  def test_skeleton_ruby_evals_do_not_depend_on_file_context
    offenders = ruby_evals.filter_map do |e|
      code = e["code"] || e["script"]
      e["id"] if code.match?(/\brequire_relative\b|__dir__|__FILE__/)
    end
    assert_empty offenders,
                 "ruby evals must not use require_relative/__dir__/__FILE__ (use Dir.pwd, the runner chdirs to the repo root): #{offenders.join(', ')}"
  end

  def test_skeleton_ruby_evals_are_valid_ruby
    ruby_evals.each do |e|
      code = e["code"] || e["script"]
      begin
        RubyVM::InstructionSequence.compile(code)
      rescue SyntaxError => err
        flunk "ruby eval #{e['id']} has a syntax error: #{err.message}"
      end
    end
  end

  # A broken snippet must be reported as one FAILED eval; it must not abort the runner.
  def test_runner_reports_load_errors_and_keeps_going
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "bin"))
      FileUtils.mkdir_p(File.join(dir, "workshop"))
      FileUtils.cp(File.join(REPO_ROOT, "bin", "workshop_eval.rb"), File.join(dir, "bin"))
      FileUtils.cp_r(File.join(REPO_ROOT, "lib"), dir)
      File.write(File.join(dir, "workshop", "skeleton.yaml"), {
        "steps" => [{
          "number" => 1, "title" => "Synthetic",
          "evals" => [
            { "id" => "load-error", "type" => "ruby", "description" => "LoadError", "code" => "require_relative 'nope'" },
            { "id" => "std-error", "type" => "ruby", "description" => "StandardError", "code" => "raise 'boom'" },
            { "id" => "ok", "type" => "ruby", "description" => "Passes", "code" => "1 + 1" }
          ]
        }]
      }.to_yaml)

      stdout, _stderr, status = Open3.capture3("ruby", File.join(dir, "bin", "workshop_eval.rb"), "1")
      assert_equal 1, status.exitstatus
      assert_includes stdout, "Evaluation Summary: 1/3 Passed, 2 Failed", "runner must finish and print a summary:\n#{stdout}"
      assert_includes stdout, "cannot infer basepath", "the LoadError message must be shown to the attendee"
    end
  end
end
