#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'fileutils'

script_dir = File.dirname(File.expand_path(__FILE__))
workshop_dir = File.expand_path('..', script_dir)
yaml_path = File.join(workshop_dir, 'skeleton.yaml')
output_path = File.join(workshop_dir, 'SKELETON.md')

unless File.exist?(yaml_path)
  warn "❌ [build_skeleton] #{yaml_path} not found!"
  exit 1
end

puts "📄 Reading declarative skeleton from #{yaml_path}..."
data = YAML.load_file(yaml_path)
steps = data['steps'] || []

lines = []
lines << "<!-- ⚠️ AGENT WARNING: This file (SKELETON.md) is compiled from workshop/skeleton.yaml. DO NOT EDIT DIRECTLY! -->"
lines << "<!-- 📜 Adheres to docs/CONSTITUTION.md (v#{data['version'] || '1.1.0'}) -->"
lines << "# Workshop Skeleton"
lines << ""
lines << "This is the canonical high-level roadmap and step breakdown for the Rails 8 on Google Cloud workshop, designed around the **3 Progressive Cloud Run Deployments**, **Zero-Branch Time-Machine overlays**, and **Google Antigravity pair programming**:"
lines << ""
lines << "### 🏛️ Target Reference Architecture"
lines << ""
lines << "![Rails 8 on Google Cloud: Production Reference Architecture](assets/images/nanobanana_arch_flat.png)"
lines << ""
lines << "---"
lines << ""

steps.each do |step|
  num = step['number']
  title = step['title']
  desc = step['description']
  pseudocode = step['pseudocode']&.strip
  prereqs = step['prerequisites'] || []
  postreqs = step['postrequisites'] || []
  evals = step['evals'] || []

  lines << "### Step #{num}: #{title}"
  lines << "- **`description`**: #{desc}"
  
  if prereqs.any?
    lines << "- **`prerequisites`**:"
    prereqs.each { |pr| lines << "  - #{pr}" }
  end

  if pseudocode && !pseudocode.empty?
    lines << "- **`pseudocode`**:"
    lines << "  ```bash"
    pseudocode.each_line { |l| lines << "  #{l.rstrip}" }
    lines << "  ```"
  end

  if postreqs.any?
    lines << "- **`postrequisites`**:"
    postreqs.each { |po| lines << "  - #{po}" }
  end

  if evals.any?
    lines << "- **`evals`**:"
    evals.each do |ev|
      lines << "  - `[#{ev['type'].upcase}]` #{ev['description']}"
    end
  end

  lines << ""
  lines << "---"
  lines << ""
end

lines << "## 🎯 Verification Checklist"
lines << ""
steps.each do |step|
  lines << "- [x] Step #{step['number']}: #{step['title']}"
end
lines << ""

File.write(output_path, lines.join("\n"))
puts "✅ Successfully compiled #{output_path} from #{yaml_path} (#{steps.size} steps)."
