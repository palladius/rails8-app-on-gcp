#!/usr/bin/env ruby

require 'erb'
require 'fileutils'
require 'yaml'
begin
  require 'kramdown'
  require 'kramdown-parser-gfm'
rescue LoadError
  puts "Missing kramdown gem. Please run `gem install kramdown kramdown-parser-gfm`"
  exit 1
end

puts "🏗️ Building Codelab static multi-doc site..."

def parse_markdown(file_path)
  content = File.read(file_path)
  frontmatter = {}
  
  if content =~ /\A(---\s*\n.*?\n?^---\s*$\n?)/m
    frontmatter_raw = $1
    content = content.sub(frontmatter_raw, '')
    begin
      frontmatter = YAML.safe_load(frontmatter_raw)
    rescue => e
      puts "⚠️ Error parsing frontmatter: #{e.message}"
    end
  end
  
  main_title = frontmatter['title']
  if content =~ /^#\s+(.+)$/
    main_title ||= $1.strip
    content = content.sub(/^#\s+.+$/, '')
  end
  main_title ||= File.basename(file_path, '.md').capitalize
  
  parts = content.split(/^##\s+/)
  if parts.size <= 1 && content =~ /^###\s+/
    parts = content.split(/^###\s+/)
  end
  
  steps = []
  
  first_part = parts.shift
  if first_part && first_part.strip.length > 0 && first_part.gsub(/<!--.*?-->/m, '').strip.length > 0
    steps << {
      title: "Overview",
      content: first_part
    }
  end
  
  parts.each do |part|
    lines = part.lines
    title = lines.shift.strip
    body = lines.join
    
    steps << {
      title: title,
      content: "## " + title + "\n" + body
    }
  end
  
  {
    title: main_title,
    frontmatter: frontmatter,
    steps: steps
  }
end

def render_markdown(text)
  Kramdown::Document.new(text, input: 'GFM', syntax_highlighter: nil).to_html
end

# Extract template from server.rb
server_code = File.read('server.rb')
template_string = server_code.split("@@index\n").last

build_dir = 'build'
FileUtils.mkdir_p(build_dir)

docs_to_build = [
  { source: 'CODELAB.md', target: 'index.html', active: 'codelab' },
  { source: 'UNTOUCHABLE-CONSTITUTION.md', target: 'constitution.html', active: 'constitution' },
  { source: 'SKELETON.md', target: 'skeleton.html', active: 'skeleton' }
]

docs_to_build.each do |doc|
  next unless File.exist?(doc[:source])
  
  @active_doc = doc[:active]
  @codelab = parse_markdown(doc[:source])
  
  # For static pages, adapt the tab links to point to the static HTML files
  doc_template = template_string.dup
  doc_template.gsub!('href="/codelab"', 'href="index.html"')
  doc_template.gsub!('href="/constitution"', 'href="constitution.html"')
  doc_template.gsub!('href="/skeleton"', 'href="skeleton.html"')
  
  renderer = ERB.new(doc_template)
  html = renderer.result(binding)
  
  target_file = File.join(build_dir, doc[:target])
  File.write(target_file, html)
  puts "   📄 Rendered #{doc[:source]} -> #{build_dir}/#{doc[:target]}"
end

# Copy assets
if Dir.exist?('assets')
  FileUtils.mkdir_p(File.join(build_dir, 'assets'))
  FileUtils.cp_r(Dir.glob('assets/*'), File.join(build_dir, 'assets/'))
end

puts "✅ Successfully built multi-doc static site into workshop/#{build_dir}/"
