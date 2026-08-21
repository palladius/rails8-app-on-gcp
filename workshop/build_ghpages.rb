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

puts "🏗️ Building Codelab static site (White/Google version)..."

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
  main_title ||= "Codelab Workshop"
  
  parts = content.split(/^##\s+/)
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

# 1. Parse Markdown
@codelab = parse_markdown('CODELAB.md')

# 2. Extract the @@index template from server.rb
server_code = File.read('server.rb')
template_string = server_code.split("@@index\n").last

# 3. Render the ERB template
renderer = ERB.new(template_string)
html = renderer.result(binding)

# 4. Write to build/ directory
build_dir = 'build'
FileUtils.mkdir_p(build_dir)
File.write(File.join(build_dir, 'index.html'), html)

# 5. Copy assets
if Dir.exist?('assets')
  FileUtils.mkdir_p(File.join(build_dir, 'assets'))
  FileUtils.cp_r(Dir.glob('assets/*'), File.join(build_dir, 'assets/'))
end

puts "✅ Successfully built White/Google static site into workshop/#{build_dir}/"
