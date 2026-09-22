# frozen_string_literal: true

require "minitest/autorun"
require_relative "../workshop/telemetry/friction_log"
require_relative "../workshop/telemetry/visualizer"

class FrictionLogVisualizerTest < Minitest::Test
  def setup
    yaml_path = File.expand_path("../workshop/telemetry/friction_logs.yaml", __dir__)
    @logs = FrictionLog.load_all(yaml_path)
    @visualizer = FrictionLogVisualizer.new(@logs)
  end

  def test_render_gantt_svg
    svg = @visualizer.render_gantt_svg
    assert_includes svg, "<svg"
    assert_includes svg, "</svg>"
    # Verifies all logs are represented
    @logs.each do |log|
      assert_includes svg, log.id
    end
    # Verifies pause rendering
    assert_includes svg, "pause-bar"
    assert_includes svg, "Ruby 4.0.5 URI parser bug"
  end

  def test_render_concurrency_svg
    svg = @visualizer.render_concurrency_svg
    assert_includes svg, "<svg"
    assert_includes svg, "FL006"
    assert_includes svg, "FL007"
    assert_includes svg, "4a2f81a" # Shared codebase baseline commit SHA
    assert_includes svg, "#113"   # FL006 PR
    assert_includes svg, "#133"   # FL007 PR
  end

  def test_render_step_durations_svg
    svg = @visualizer.render_step_durations_svg
    assert_includes svg, "<svg"
    assert_includes svg, "Step 0"
    assert_includes svg, "Step 8"
    assert_includes svg, "FL004" # Best-timed run
  end

  def test_render_bug_trends_svg
    svg = @visualizer.render_bug_trends_svg
    assert_includes svg, "<svg"
    assert_includes svg, "Bugs Uncovered"
    assert_includes svg, "FL006"
  end

  def test_render_html_dashboard
    html = @visualizer.render_html_dashboard
    assert_includes html, "<!DOCTYPE html>"
    assert_includes html, "Friction Log Telemetry"
    assert_includes html, "FL000"
    assert_includes html, "FL007"
    assert_includes html, "rails8-fl006-20260911"
    assert_includes html, "rails8-fl007-20260916"
  end
end
