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

  # A "verify" eval must never rewrite the attendee's credentials: `ensure!` can regenerate
  # master.key / credentials.yml.enc. Use the read-only `check` (PR #175 review).
  def test_no_ruby_eval_mutates_credentials_via_ensure
    offenders = ruby_evals.filter_map { |e| e["id"] if (e["code"] || e["script"]).include?("ensure!") }
    assert_empty offenders, "ruby evals must use the read-only WorkshopCredentialsManager.check, not ensure!: #{offenders.join(', ')}"
  end

  def test_master_key_eval_fails_without_touching_an_unpaired_key_and_credentials
    code = ruby_evals.find { |e| e["id"] == "step-5-ruby-master-key" }["code"]
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "bin"))
      FileUtils.mkdir_p(File.join(dir, "blog", "config"))
      FileUtils.cp(File.join(REPO_ROOT, "bin", "ensure_workshop_credentials.rb"), File.join(dir, "bin"))
      key_path = File.join(dir, "blog", "config", "master.key")
      cred_path = File.join(dir, "blog", "config", "credentials.yml.enc")
      File.write(key_path, "0123456789abcdef0123456789abcdee\n")
      File.write(cred_path, "not-a-valid-encrypted-file\n")

      script = "Dir.chdir(ARGV[0]) { eval(File.read(ARGV[1])) }"
      File.write(File.join(dir, "snippet.rb"), code)
      _out, err, status = Open3.capture3("ruby", "-e", script, dir, File.join(dir, "snippet.rb"))

      refute status.success?, "an unpaired master.key/credentials.yml.enc must fail the eval"
      assert_match(/cannot decrypt|sample|dummy/i, err)
      assert_equal "0123456789abcdef0123456789abcdee\n", File.read(key_path), "the eval must not rewrite master.key"
      assert_equal "not-a-valid-encrypted-file\n", File.read(cred_path), "the eval must not rewrite credentials.yml.enc"
    end
  end

  def test_master_key_eval_passes_for_a_valid_pair_and_does_not_modify_it
    code = ruby_evals.find { |e| e["id"] == "step-5-ruby-master-key" }["code"]
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "bin"))
      FileUtils.mkdir_p(File.join(dir, "blog", "config"))
      FileUtils.cp(File.join(REPO_ROOT, "bin", "ensure_workshop_credentials.rb"), File.join(dir, "bin"))
      key = "a1b2c3d4e5f60718293a4b5c6d7e8f90"
      File.write(File.join(dir, "blog", "config", "master.key"), "#{key}\n")
      cred_path = File.join(dir, "blog", "config", "credentials.yml.enc")
      setup = "require File.join(ARGV[0], 'bin/ensure_workshop_credentials'); WorkshopCredentialsManager.write_encrypted_credentials!(ARGV[1], ARGV[2])"
      _o, e, s = Open3.capture3("ruby", "-e", setup, dir, key, cred_path)
      assert s.success?, e
      before = File.binread(cred_path)

      File.write(File.join(dir, "snippet.rb"), code)
      _out, err, status = Open3.capture3("ruby", "-e", "Dir.chdir(ARGV[0]) { eval(File.read(ARGV[1])) }", dir, File.join(dir, "snippet.rb"))
      assert status.success?, "a valid master.key/credentials.yml.enc pair must pass the eval: #{err}"
      assert_equal before, File.binread(cred_path)
    end
  end
end
