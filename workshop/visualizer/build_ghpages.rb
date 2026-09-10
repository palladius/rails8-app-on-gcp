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

# Ensure we operate with workshop/ as the reference directory for sources and output
script_dir = File.dirname(File.expand_path(__FILE__))
workshop_dir = File.expand_path('..', script_dir)
repo_root = File.expand_path('..', workshop_dir)

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
server_rb_path = File.join(script_dir, 'server.rb')
server_code = File.read(server_rb_path)
template_string = server_code.split("@@index\n").last.split("@@portal\n").first

build_dir = File.join(workshop_dir, 'build')
FileUtils.mkdir_p(build_dir)

docs_to_build = [
  { source: File.join(workshop_dir, 'CODELAB.md'), target: 'workshop/index.html', active: 'codelab', base_prefix: '../' },
  { source: File.join(workshop_dir, 'CODELAB.md'), target: 'codelab/index.html', active: 'codelab', base_prefix: '../' },
  { source: File.join(workshop_dir, 'CODELAB.md'), target: 'codelab.html', active: 'codelab', base_prefix: '' },
  { source: File.join(repo_root, 'docs', 'CONSTITUTION.md'), target: 'constitution.html', active: 'constitution', base_prefix: '' },
  { source: File.join(workshop_dir, 'SKELETON.md'), target: 'skeleton.html', active: 'skeleton', base_prefix: '' }
]

docs_to_build.each do |doc|
  next unless File.exist?(doc[:source])
  
  @active_doc = doc[:active]
  @codelab = parse_markdown(doc[:source])
  prefix = doc[:base_prefix] || ''
  
  # For static pages, adapt the tab links to point to the static HTML files
  doc_template = template_string.dup
  doc_template.gsub!('href="/workshop/"', "href=\"#{prefix}workshop/index.html\"")
  doc_template.gsub!('href="/codelab"', "href=\"#{prefix}workshop/index.html\"")
  doc_template.gsub!('href="/constitution"', "href=\"#{prefix}constitution.html\"")
  doc_template.gsub!('href="/skeleton"', "href=\"#{prefix}skeleton.html\"")
  doc_template.gsub!('href="/slides/"', "href=\"#{prefix}slides/index.html\"")
  doc_template.gsub!('href="/"', "href=\"#{prefix}index.html\"")
  # Hide Constitution & Skeleton from primary static doc tabs in codelab viewer
  if doc[:active] == 'codelab'
    doc_template.gsub!(%r{<a href="[^"]*constitution\.html"[^>]*>.*?</a>\s*}m, '')
    doc_template.gsub!(%r{<a href="[^"]*skeleton\.html"[^>]*>.*?</a>\s*}m, '')
  end
  
  renderer = ERB.new(doc_template)
  html = renderer.result(binding)
  
  target_file = File.join(build_dir, doc[:target])
  FileUtils.mkdir_p(File.dirname(target_file))
  File.write(target_file, html)
  puts "   📄 Rendered #{File.basename(doc[:source])} -> workshop/build/#{doc[:target]}"
end

# Render the minimal root portal page at index.html (EN) and index_it.html (IT)
portal_template_string = server_code.split("@@portal\n").last.split("@@").first

[
  { lang: 'en', filename: 'index.html' },
  { lang: 'it', filename: 'index_it.html' }
].each do |target|
  @lang = target[:lang]
  portal_renderer = ERB.new(portal_template_string)
  portal_html = portal_renderer.result(binding)
  # Adjust links for static output in root
  portal_html.gsub!('href="?lang=en"', 'href="index.html"')
  portal_html.gsub!('href="?lang=it"', 'href="index_it.html"')
  portal_html.gsub!('href="/workshop/"', 'href="workshop/index.html"')
  portal_html.gsub!('href="/codelab"', 'href="workshop/index.html"')
  portal_html.gsub!('href="/slides/"', 'href="slides/index.html"')
  portal_html.gsub!('href="/constitution"', 'href="constitution.html"')
  portal_html.gsub!('href="/skeleton"', 'href="skeleton.html"')
  portal_html.gsub!('src="/assets/', 'src="assets/')

  File.write(File.join(build_dir, target[:filename]), portal_html)
  puts "   📄 Rendered Landing Portal (#{target[:lang].upcase}) -> workshop/build/#{target[:filename]}"
end

# Copy workshop assets to build/assets, build/workshop/assets, and build/codelab/assets
assets_dir = File.join(workshop_dir, 'assets')
if Dir.exist?(assets_dir)
  FileUtils.mkdir_p(File.join(build_dir, 'assets'))
  FileUtils.cp_r(Dir.glob(File.join(assets_dir, '*')), File.join(build_dir, 'assets/'))
  FileUtils.mkdir_p(File.join(build_dir, 'workshop', 'assets'))
  FileUtils.cp_r(Dir.glob(File.join(assets_dir, '*')), File.join(build_dir, 'workshop', 'assets/'))
  FileUtils.mkdir_p(File.join(build_dir, 'codelab', 'assets'))
  FileUtils.cp_r(Dir.glob(File.join(assets_dir, '*')), File.join(build_dir, 'codelab', 'assets/'))
end

# Compile and copy presentation slides
slides_source_dir = File.join(repo_root, 'slides')
slides_dist_dir = File.join(slides_source_dir, 'dist')
slides_build_dir = File.join(build_dir, 'slides')
FileUtils.mkdir_p(slides_build_dir)

# Ensure slides are compiled to slides/dist/index.html
system("cd #{repo_root} && just build-slides") unless File.exist?(File.join(slides_dist_dir, 'index.html'))

if File.exist?(File.join(slides_dist_dir, 'index.html'))
  FileUtils.cp(File.join(slides_dist_dir, 'index.html'), File.join(slides_build_dir, 'index.html'))
  puts "   📄 Copied Marp Presentation Slides -> workshop/build/slides/index.html"
end

slides_images_dir = File.join(slides_source_dir, 'images')
if Dir.exist?(slides_images_dir)
  FileUtils.mkdir_p(File.join(slides_build_dir, 'images'))
  FileUtils.cp_r(Dir.glob(File.join(slides_images_dir, '*')), File.join(slides_build_dir, 'images/'))
  puts "   🖼️  Copied Slides Images -> workshop/build/slides/images/"
end

puts "✅ Successfully built multi-doc static site into #{build_dir}/"

