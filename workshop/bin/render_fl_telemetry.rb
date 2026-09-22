#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require_relative "../telemetry/friction_log"
require_relative "../telemetry/visualizer"

ROOT_DIR = File.expand_path("../..", __dir__)
TELEMETRY_DIR = File.join(ROOT_DIR, "workshop", "telemetry")
YAML_FILE = File.join(TELEMETRY_DIR, "friction_logs.yaml")
OUTPUT_DIR = File.join(TELEMETRY_DIR, "output")

FileUtils.mkdir_p(OUTPUT_DIR)

puts "📥 Loading Friction Logs dataset from #{YAML_FILE}..."
logs = FrictionLog.load_all(YAML_FILE)
puts "Loaded #{logs.size} Friction Logs: #{logs.map(&:id).join(', ')}"

visualizer = FrictionLogVisualizer.new(logs)

charts = {
  "fl_gantt_timeline" => visualizer.render_gantt_svg,
  "fl_concurrency_fl06_fl07" => visualizer.render_concurrency_svg,
  "fl_step_durations" => visualizer.render_step_durations_svg,
  "fl_bugs_trend" => visualizer.render_bug_trends_svg
}

charts.each do |filename_base, svg_content|
  svg_path = File.join(OUTPUT_DIR, "#{filename_base}.svg")
  png_path = File.join(OUTPUT_DIR, "#{filename_base}.png")

  File.write(svg_path, svg_content)
  puts "✅ Rendered SVG: #{svg_path} (#{File.size(svg_path)} bytes)"

  # Rasterize to PNG via convert / rsvg-convert if available
  if system("which convert >/dev/null 2>&1")
    # ImageMagick 7 convert
    cmd = "convert -background none -density 150 #{svg_path} #{png_path} 2>/dev/null"
    if system(cmd) && File.exist?(png_path)
      puts "  🎨 Rasterized PNG: #{png_path} (#{File.size(png_path)} bytes)"
    else
      puts "  ⚠️ Failed to convert #{svg_path} to PNG"
    end
  end
end

html_path = File.join(OUTPUT_DIR, "index.html")
File.write(html_path, visualizer.render_html_dashboard)
puts "✅ Rendered Interactive HTML Dashboard: #{html_path} (#{File.size(html_path)} bytes)"

puts "\n🎉 All telemetry visualizations generated in #{OUTPUT_DIR}!"
