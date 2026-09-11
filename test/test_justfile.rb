# frozen_string_literal: true

# Guards the root justfile against syntax that only parses on bleeding-edge `just`.
#
# Context: `just` only allowed star (variadic) parameters to follow default parameters
# starting from v1.40.0 (2025-03-09). Distro packages are much older (Debian/Ubuntu ship
# 1.2x), and on those a single offending recipe makes the WHOLE justfile unparseable:
# every recipe dies with "Non-default parameter `flags` follows default parameter".
# Workshop attendees hit this on `just slides`, `just dev`, ... i.e. on step zero.
require "minitest/autorun"

class JustfileTest < Minitest::Test
  JUSTFILE_PATH = File.expand_path("../justfile", __dir__)

  # e.g. `screenshots filter="" *flags="":` — recipe name, parameters, colon
  RECIPE_LINE = /\A([a-zA-Z0-9_-]+)([^:]*):(?!=)/
  NON_RECIPE_KEYWORDS = %w[alias set export import mod].freeze

  def setup
    @lines = File.readlines(JUSTFILE_PATH, chomp: true)
  end

  def test_no_required_parameter_follows_a_default_one
    offenders = []

    each_recipe do |name, params, lineno|
      seen_default = false
      params.each do |param|
        has_default = param.include?("=")
        offenders << "line #{lineno}: recipe `#{name}` takes `#{param}` after a defaulted parameter" if seen_default && !has_default
        seen_default ||= has_default
      end
    end

    assert_empty offenders, <<~MSG
      justfile uses a parameter ordering that requires just >= 1.40.0:
      #{offenders.join("\n")}

      Give the trailing parameter a default (e.g. `*flags=""`) so the justfile keeps
      parsing on the `just` versions shipped by Debian/Ubuntu.
    MSG
  end

  def test_justfile_parses_with_the_locally_installed_just
    skip "`just` is not installed" unless system("command -v just > /dev/null 2>&1")

    output = `just --justfile #{JUSTFILE_PATH} --summary 2>&1`
    assert $?.success?, "`just --summary` failed:\n#{output}"
    assert_includes output, "slides", "Expected the `slides` recipe to be listed"
  end

  private

  def each_recipe
    @lines.each_with_index do |line, index|
      next if line.start_with?("#", " ", "\t")
      next if line.strip.empty?

      match = RECIPE_LINE.match(line)
      next unless match
      next if NON_RECIPE_KEYWORDS.include?(match[1])

      params = match[2].to_s.split(/\s+/).reject(&:empty?)
      yield match[1], params, index + 1
    end
  end
end
