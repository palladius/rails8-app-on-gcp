# frozen_string_literal: true

# Guards workshop/constraints.yaml, the registry of rules the workshop depends on.
#
# Why it exists: the same kind of mistake kept coming back. A change made one thing better and
# silently broke a rule nobody had written down (example: replacing real addresses with
# placeholders in .env.dist broke `terraform apply`, because every IAP_ALLOWED_USERS entry
# becomes an IAM binding). Each constraint is written down once and points at the test that
# enforces it. This file checks that the registry cannot rot: every guard it names must exist.
require "minitest/autorun"
require "yaml"

class WorkshopConstraintsTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)
  REGISTRY_PATH = File.join(REPO_ROOT, "workshop", "constraints.yaml")
  REQUIRED_KEYS = %w[id rule why breaks_as learned_from].freeze

  def setup
    assert File.exist?(REGISTRY_PATH), "workshop/constraints.yaml must exist"
    @constraints = YAML.load_file(REGISTRY_PATH).fetch("constraints")
  end

  def test_every_constraint_is_complete_and_ids_are_unique
    refute_empty @constraints
    @constraints.each do |c|
      missing = REQUIRED_KEYS.reject { |k| c[k].to_s.strip != "" }
      assert_empty missing, "constraint #{c['id'].inspect} is missing: #{missing.join(', ')}"
      assert_match(/\AWC-\d{2}\z/, c["id"], "constraint ids look like WC-01")
    end
    ids = @constraints.map { |c| c["id"] }
    assert_equal ids.uniq, ids, "constraint ids must be unique"
  end

  def test_every_constraint_is_either_guarded_by_a_test_or_says_why_not
    @constraints.each do |c|
      guards = Array(c["guarded_by"])
      unguarded = c["unguarded"]
      assert guards.any? ^ !unguarded.nil?,
             "#{c['id']}: give either `guarded_by` (tests) or `unguarded` (reason + issue), not both and not neither"
      next if guards.any?

      assert unguarded["reason"].to_s.strip != "", "#{c['id']}: `unguarded` needs a reason"
      assert_kind_of Integer, unguarded["issue"], "#{c['id']}: `unguarded` needs the number of an open issue"
    end
  end

  def test_every_named_guard_exists_in_the_named_file
    @constraints.each do |c|
      Array(c["guarded_by"]).each do |guard|
        path = File.join(REPO_ROOT, guard.fetch("file"))
        assert File.exist?(path), "#{c['id']}: guard file #{guard['file']} does not exist"
        name = guard.fetch("test")
        source = File.read(path)
        found = source.include?("def #{name}\n") || source.include?(%(test "#{name}" do))
        assert found, "#{c['id']}: #{guard['file']} has no test named #{name.inspect}; the registry and the tests have drifted"
      end
    end
  end
end
