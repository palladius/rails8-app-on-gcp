#!/usr/bin/env ruby

require 'json'
require 'fileutils'

puts "✂️ Splitting CODELAB.md for Blue/Black Glassmorphism SPA..."

content = File.read('CODELAB.md')

# Strip frontmatter
content.sub!(/\A(---\s*\n.*?\n?^---\s*$\n?)/m, '')
# Strip H1
content.sub!(/^#\s+.+$/, '')

parts = content.split(/^##\s+/)
first_part = parts.shift

pages = []
out_dir = 'render-app2/pages'
FileUtils.mkdir_p(out_dir)
# Clean existing pages
FileUtils.rm_f(Dir.glob("#{out_dir}/*.md"))

idx = 1

if first_part && first_part.strip.length > 0 && first_part.gsub(/<!--.*?-->/m, '').strip.length > 0
  filename = "01-overview.md"
  File.write("#{out_dir}/#{filename}", "# Overview\n" + first_part)
  pages << filename
  idx += 1
end

parts.each do |part|
  title = part.lines.first.strip
  # Safe filename
  safe_name = title.downcase.gsub(/[^a-z0-9]+/, '-')
  filename = "#{sprintf('%02d', idx)}-#{safe_name}.md"
  
  # Ensure the title has an H1 since render-app2 uses H1 for title extraction
  File.write("#{out_dir}/#{filename}", "# " + title + "\n" + part.lines[1..-1].join)
  pages << filename
  idx += 1
end

File.write("#{out_dir}/pages.json", JSON.pretty_generate(pages))

# Copy assets so relative links in Markdown resolve
if Dir.exist?('assets')
  FileUtils.mkdir_p("render-app2/assets")
  FileUtils.cp_r(Dir.glob('assets/*'), "render-app2/assets/")
end

puts "✅ Generated #{pages.length} pages in workshop/#{out_dir}/"
