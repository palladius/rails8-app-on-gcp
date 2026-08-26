#!/usr/bin/env ruby
#
=begin
This is a Sinatra-based web server that visualizes a generic CODELAB.md (or similar Markdown files)
in a multi-page workshop format similar to Google Codelabs.

It parses the Markdown file, splits it by H2 headers (##) into separate steps,
and serves a clean, responsive web interface with:
- A sidebar navigation listing all steps.
- Prev/Next buttons for stepping through.
- Custom styled boxes (like info/warning boxes).
- Multi-document switcher (Codelab, Constitution, Skeleton).
- Live interactive Mermaid diagram rendering.
- Hot-reloading (reads and parses the markdown file on every request, so refreshing the browser shows changes immediately).

Usage:
  ./server.rb [options] [path_to_markdown_file]

Run with -h or --help to see all options.
=end

# Set up environment for user-installed gems to ensure write access
ENV['GEM_HOME'] = Gem.user_dir
ENV['GEM_PATH'] = Gem.user_dir
Gem.clear_paths

# List of required gems for the server to run
REQUIRED_GEMS = {
  'sinatra' => 'sinatra/base',
  'kramdown' => 'kramdown',
  'kramdown-parser-gfm' => 'kramdown-parser-gfm',
  'puma' => 'puma',
  'rackup' => 'rackup'
}

missing_gems = []
REQUIRED_GEMS.each do |gem_name, require_name|
  begin
    require require_name
  rescue LoadError
    missing_gems << gem_name
  end
end

if missing_gems.any?
  puts "🔍 Missing gems: #{missing_gems.join(', ')}"
  puts "🚀 Installing them to user gem home (~/.local/share/gem/ruby)..."
  success = system("gem install --user-install #{missing_gems.join(' ')}")
  if success
    Gem.clear_paths
    missing_gems.each do |gem_name|
      require REQUIRED_GEMS[gem_name]
    end
  else
    puts "❌ Error: Failed to install gems automatically."
    puts "Please install manually with: gem install --user-install #{missing_gems.join(' ')}"
    exit 1
  end
end

require 'yaml'
require 'json'
require 'optparse'

# Parse Command Line Options
cli_options = {
  port: 8080,
  bind: 'localhost',
  file: nil
}

OptionParser.new do |opts|
  opts.banner = "Usage: server.rb [options] [markdown_file]"
  
  opts.on("-p", "--port PORT", Integer, "Port to run the server on (default: 8080)") do |p|
    cli_options[:port] = p
  end
  
  opts.on("-b", "--bind BIND", "IP address to bind the server to (default: localhost)") do |b|
    cli_options[:bind] = b
  end
  
  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

# If a file is specified as the remaining argument
if ARGV.any?
  cli_options[:file] = ARGV.first
else
  # Default files to check in priority order
  default_files = ['./CODELAB.md', './WORKSHOP.md', '../CODELAB.md', '../workshop/CODELAB.md']
  cli_options[:file] = default_files.find { |f| File.exist?(f) }
  cli_options[:file] ||= Dir.glob('*.md').first
end

if cli_options[:file].nil? || !File.exist?(cli_options[:file])
  puts "❌ Error: Markdown file not found!"
  puts "Please specify a markdown file: ruby server.rb path/to/file.md"
  exit 1
end

# Define the Sinatra App
CLI_OPTIONS = cli_options

class CodelabServer < Sinatra::Base
  enable :inline_templates
  set :port, CLI_OPTIONS[:port]
  set :bind, CLI_OPTIONS[:bind]
  set :base_dir, File.dirname(File.expand_path(CLI_OPTIONS[:file]))
  set :default_file, File.expand_path(CLI_OPTIONS[:file])
  
  helpers do
    def render_markdown(text)
      Kramdown::Document.new(text, input: 'GFM', syntax_highlighter: nil).to_html
    end

    def resolve_doc_path(doc_param)
      return settings.default_file if doc_param.nil? || doc_param.empty?

      case doc_param.to_s.downcase
      when 'codelab'
        candidate = File.join(settings.base_dir, 'CODELAB.md')
      when 'constitution'
        candidate = File.join(settings.base_dir, 'UNTOUCHABLE-CONSTITUTION.md')
      when 'skeleton'
        candidate = File.join(settings.base_dir, 'SKELETON.md')
      else
        candidate = File.expand_path(doc_param, settings.base_dir)
      end

      File.exist?(candidate) ? candidate : settings.default_file
    end

    def current_doc_type(file_path)
      base = File.basename(file_path).downcase
      if base.include?('constitution')
        'constitution'
      elsif base.include?('skeleton')
        'skeleton'
      else
        'codelab'
      end
    end
  end
  
  # Main route
  get '/' do
    target_file = if params[:doc]
                    resolve_doc_path(params[:doc])
                  elsif params[:file]
                    resolve_doc_path(params[:file])
                  else
                    settings.default_file
                  end
    @active_doc = current_doc_type(target_file)
    @codelab = parse_markdown(target_file)
    erb :index
  end

  get '/codelab' do
    target_file = resolve_doc_path('codelab')
    @active_doc = 'codelab'
    @codelab = parse_markdown(target_file)
    erb :index
  end

  get '/constitution' do
    target_file = resolve_doc_path('constitution')
    @active_doc = 'constitution'
    @codelab = parse_markdown(target_file)
    erb :index
  end

  get '/skeleton' do
    target_file = resolve_doc_path('skeleton')
    @active_doc = 'skeleton'
    @codelab = parse_markdown(target_file)
    erb :index
  end
  
  # A2UI JSON endpoint
  get '/a2ui' do
    content_type :json
    target_file = params[:doc] ? resolve_doc_path(params[:doc]) : settings.default_file
    codelab = parse_markdown(target_file)
    
    {
      a2ui: "1.0",
      metadata: {
        title: codelab[:title],
        author: codelab[:frontmatter]['author'],
        duration: codelab[:frontmatter]['duration']
      },
      components: codelab[:steps].map.with_index do |step, idx|
        {
          id: "step-#{idx}",
          type: "StepCard",
          properties: {
            index: idx,
            title: step[:title],
            content: render_markdown(step[:content])
          }
        }
      end
    }.to_json
  end

  # Catch-all route to serve local assets
  get '/*' do |path|
    md_dir = settings.base_dir
    target_path = File.expand_path(path, md_dir)
    
    # Also try relative to the git root directory (one level up from markdown file)
    git_root = File.expand_path('..', md_dir)
    git_target_path = File.expand_path(path, git_root)
    
    if target_path.start_with?(md_dir) && File.exist?(target_path) && !File.directory?(target_path)
      send_file target_path
    elsif git_target_path.start_with?(git_root) && File.exist?(git_target_path) && !File.directory?(git_target_path)
      send_file git_target_path
    else
      status 404
      "Asset not found: #{path}"
    end
  end
  
  private
  
  def parse_markdown(file_path)
    content = File.read(file_path)
    frontmatter = {}
    
    # Extract YAML frontmatter if it exists at the start of the file
    if content =~ /\A(---\s*\n.*?\n?^---\s*$\n?)/m
      frontmatter_raw = $1
      content = content.sub(frontmatter_raw, '')
      begin
        frontmatter = YAML.safe_load(frontmatter_raw)
      rescue => e
        puts "⚠️ Error parsing frontmatter: #{e.message}"
      end
    end
    
    # Find H1 for the main workshop title
    main_title = frontmatter['title']
    if content =~ /^#\s+(.+)$/
      main_title ||= $1.strip
      # Remove the main title line from content so it's not rendered inside step 0
      content = content.sub(/^#\s+.+$/, '')
    end
    main_title ||= File.basename(file_path, '.md').capitalize
    
    # Split content by H2 headers (##) or H3 if no H2
    parts = content.split(/^##\s+/)
    if parts.size <= 1 && content =~ /^###\s+/
      parts = content.split(/^###\s+/)
    end
    
    steps = []
    
    # Process text before the first header
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
        content: body
      }
    end
    
    {
      title: main_title,
      frontmatter: frontmatter,
      steps: steps
    }
  end
end

# Startup Banner
puts "\n"
puts "🚀 Starting Codelab Visualizer Server on http://#{cli_options[:bind]}:#{cli_options[:port]}"
puts "🦖 Hello, Supreme Leader and pun-master Riccardo!"
puts "📖 Default file: #{cli_options[:file]}"
puts "✨ Multi-Doc Switching Available:"
puts "   👉 Codelab     : http://#{cli_options[:bind]}:#{cli_options[:port]}/codelab"
puts "   👉 Constitution: http://#{cli_options[:bind]}:#{cli_options[:port]}/constitution"
puts "   👉 Skeleton    : http://#{cli_options[:bind]}:#{cli_options[:port]}/skeleton"
puts "💡 Tip: Edit any markdown file and refresh your browser to see updates instantly!"
puts "Press Ctrl+C to stop the server.\n\n"

# Run Sinatra app only if executed directly
if __FILE__ == $0
  CodelabServer.run!
end

__END__

@@index
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><%= @codelab[:title] %></title>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-tomorrow.min.css">
  <style>
    /* Google Codelab Font and Color Variables */
    :root {
      --primary-color: #1a73e8; /* Google Blue */
      --primary-hover: #1557b0;
      --sidebar-bg: rgba(248, 249, 250, 0.45); /* Semi-transparent */
      --border-color: rgba(218, 220, 224, 0.5); /* Transparent borders */
      --text-color: #3c4043;
      --heading-color: #202124;
      --active-bg: rgba(232, 240, 254, 0.65);
      --header-bg: rgba(255, 255, 255, 0.65);
      --footer-bg: rgba(255, 255, 255, 0.65);
    }
    
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }
    
    body {
      font-family: 'Google Sans', 'Roboto', 'Helvetica Neue', sans-serif;
      color: var(--text-color);
      display: flex;
      height: 100vh;
      overflow: hidden;
      background: linear-gradient(135deg, #f5f7fa 0%, #e4e8f0 100%);
      position: relative;
    }
    
    body::before {
      content: "";
      position: absolute;
      top: -10%;
      left: -10%;
      width: 45%;
      height: 45%;
      background: radial-gradient(circle, rgba(26, 115, 232, 0.12) 0%, rgba(26, 115, 232, 0) 70%);
      z-index: 1;
      pointer-events: none;
      filter: blur(40px);
    }
    
    body::after {
      content: "";
      position: absolute;
      bottom: -10%;
      right: -10%;
      width: 55%;
      height: 55%;
      background: radial-gradient(circle, rgba(217, 48, 37, 0.08) 0%, rgba(217, 48, 37, 0) 70%);
      z-index: 1;
      pointer-events: none;
      filter: blur(50px);
    }
    
    /* Sidebar styling with Glassmorphism */
    .sidebar {
      width: 320px;
      min-width: 320px;
      background: var(--sidebar-bg);
      backdrop-filter: blur(20px);
      -webkit-backdrop-filter: blur(20px);
      border-right: 1px solid var(--border-color);
      display: flex;
      flex-direction: column;
      height: 100%;
      z-index: 10;
    }
    
    .sidebar-header {
      padding: 20px 24px;
      border-bottom: 1px solid var(--border-color);
      background: rgba(255, 255, 255, 0.4);
    }
    
    .codelab-title {
      font-size: 17px;
      font-weight: 600;
      color: var(--heading-color);
      line-height: 1.4;
    }

    /* Doc Switcher Pills */
    .doc-switcher {
      display: flex;
      background: rgba(0, 0, 0, 0.06);
      padding: 3px;
      border-radius: 8px;
      margin-top: 12px;
      gap: 2px;
    }

    .doc-tab {
      flex: 1;
      text-align: center;
      padding: 6px 4px;
      font-size: 11px;
      font-weight: 500;
      text-decoration: none;
      color: #5f6368;
      border-radius: 6px;
      transition: all 0.2s;
    }

    .doc-tab:hover {
      color: var(--heading-color);
      background: rgba(255, 255, 255, 0.5);
    }

    .doc-tab.active {
      background: #ffffff;
      color: var(--primary-color);
      box-shadow: 0 1px 3px rgba(0,0,0,0.1);
      font-weight: 600;
    }
    
    .sidebar-menu {
      flex: 1;
      overflow-y: auto;
      padding: 12px 0;
    }
    
    .sidebar-item {
      display: flex;
      align-items: center;
      padding: 12px 24px;
      text-decoration: none;
      color: #5f6368;
      font-size: 14px;
      border-left: 4px solid transparent;
      transition: all 0.2s;
    }
    
    .sidebar-item:hover {
      background: rgba(255, 255, 255, 0.25);
      color: var(--heading-color);
    }
    
    .sidebar-item.active {
      background: var(--active-bg);
      color: var(--primary-color);
      border-left-color: var(--primary-color);
      font-weight: 500;
    }
    
    .step-num {
      width: 24px;
      height: 24px;
      border-radius: 50%;
      background-color: rgba(0, 0, 0, 0.08);
      color: #5f6368;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      margin-right: 16px;
      font-size: 11px;
      font-weight: bold;
      flex-shrink: 0;
    }
    
    .sidebar-item.active .step-num {
      background-color: var(--primary-color);
      color: #ffffff;
    }
    
    .sidebar-item.completed .step-num {
      background-color: #137333; /* Google Green */
      color: #ffffff;
    }
    
    /* Main layout */
    .main-layout {
      display: flex;
      flex-direction: column;
      flex: 1;
      height: 100%;
      position: relative;
    }
    
    /* Header styling with Glassmorphism */
    .top-header {
      height: 64px;
      background: var(--header-bg);
      backdrop-filter: blur(10px);
      -webkit-backdrop-filter: blur(10px);
      border-bottom: 1px solid var(--border-color);
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 40px;
      z-index: 5;
    }
    
    .current-step-title {
      font-size: 20px;
      font-weight: 400;
      color: var(--heading-color);
    }
    
    .metadata-info {
      display: flex;
      align-items: center;
      gap: 16px;
      font-size: 14px;
      color: #5f6368;
    }
    
    .metadata-item {
      display: flex;
      align-items: center;
      gap: 6px;
    }
    
    /* Content styling */
    .content-area {
      flex: 1;
      overflow-y: auto;
      padding: 40px;
      scroll-behavior: smooth;
      z-index: 2;
    }
    
    .content-container {
      max-width: 840px;
      margin: 0 auto;
      background: rgba(255, 255, 255, 0.75);
      backdrop-filter: blur(16px);
      -webkit-backdrop-filter: blur(16px);
      border: 1px solid rgba(255, 255, 255, 0.5);
      border-radius: 16px;
      padding: 48px;
      box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.06);
      margin-bottom: 100px;
    }
    
    .step-content {
      line-height: 1.6;
      font-size: 16px;
    }
    
    .step-content h1, .step-content h2, .step-content h3, .step-content h4 {
      color: var(--heading-color);
      margin-top: 24px;
      margin-bottom: 16px;
      font-weight: 500;
    }
    
    .step-content h2 { font-size: 22px; border-bottom: 1px solid var(--border-color); padding-bottom: 8px; }
    .step-content h3 { font-size: 18px; }
    .step-content h4 { font-size: 16px; font-weight: 600; }
    
    .step-content p { margin-bottom: 16px; }
    .step-content ul, .step-content ol { margin-bottom: 16px; padding-left: 24px; }
    .step-content li { margin-bottom: 8px; }
    
    .step-content code {
      font-family: 'Roboto Mono', Consolas, Monaco, monospace;
      background-color: rgba(0, 0, 0, 0.05);
      padding: 2px 6px;
      border-radius: 4px;
      font-size: 14px;
    }
    
    .step-content pre code { background-color: transparent; padding: 0; }
    .step-content pre { margin-bottom: 24px; border-radius: 8px; overflow: hidden; }
    .step-content img { max-width: 100%; height: auto; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.12); margin: 16px 0; display: block; }
    
    /* Mermaid diagram container */
    .mermaid-container {
      background: rgba(255, 255, 255, 0.9);
      backdrop-filter: blur(8px);
      border: 1px solid var(--border-color);
      border-radius: 12px;
      padding: 24px;
      margin: 24px 0;
      display: flex;
      justify-content: center;
      align-items: center;
      overflow-x: auto;
      box-shadow: 0 2px 10px rgba(0,0,0,0.03);
    }

    .mermaid svg {
      max-width: 100%;
      height: auto;
    }

    /* Info box styling */
    .info-box {
      border-left-width: 4px;
      border-left-style: solid;
      padding: 16px 20px;
      margin: 24px 0;
      border-radius: 0 8px 8px 0;
    }
    
    .info-box p:last-child { margin-bottom: 0; }
    .info-box.positive { background-color: rgba(230, 244, 234, 0.7); border-left-color: #137333; }
    .info-box.warning { background-color: rgba(254, 247, 224, 0.7); border-left-color: #b06000; }
    .info-box.negative { background-color: rgba(252, 232, 230, 0.7); border-left-color: #c5221f; }
    
    /* Bottom Navigation Bar with Glassmorphism */
    .bottom-bar {
      height: 64px;
      background: var(--footer-bg);
      backdrop-filter: blur(10px);
      -webkit-backdrop-filter: blur(10px);
      border-top: 1px solid var(--border-color);
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 40px;
      position: absolute;
      bottom: 0;
      left: 0;
      right: 0;
      z-index: 10;
    }
    
    .btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      height: 36px;
      padding: 0 24px;
      font-size: 14px;
      font-weight: 500;
      text-decoration: none;
      border-radius: 4px;
      cursor: pointer;
      transition: background-color 0.2s;
    }
    
    .btn-primary { background-color: var(--primary-color); color: #ffffff; border: none; }
    .btn-primary:hover { background-color: var(--primary-hover); }
    .btn-secondary { background: rgba(255, 255, 255, 0.6); backdrop-filter: blur(5px); color: var(--primary-color); border: 1px solid var(--border-color); }
    .btn-secondary:hover { background: rgba(248, 249, 250, 0.8); }
    .progress-text { font-size: 14px; color: #5f6368; }
    
    .badge {
      display: inline-block;
      padding: 4px 8px;
      background-color: rgba(232, 240, 254, 0.6);
      color: #1a73e8;
      border-radius: 4px;
      font-size: 12px;
      font-weight: 500;
    }
    
    .metadata-card {
      background: rgba(248, 249, 250, 0.6);
      border: 1px solid var(--border-color);
      border-radius: 8px;
      padding: 20px;
      margin-bottom: 24px;
    }
    
    .metadata-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 16px; }
    .meta-val { font-weight: 500; color: var(--heading-color); }
    .meta-lbl { font-size: 12px; color: #5f6368; text-transform: uppercase; margin-bottom: 4px; }

    /* Mobile & Tablet Responsiveness */
    @media (max-width: 768px) {
      body {
        flex-direction: column;
        height: auto;
        min-height: 100vh;
        overflow-y: auto;
      }
      .sidebar {
        width: 100%;
        min-width: 100%;
        height: auto;
        max-height: 240px;
        border-right: none;
        border-bottom: 1px solid var(--border-color);
      }
      .main-layout {
        height: auto;
        min-height: calc(100vh - 240px);
      }
      .top-header {
        padding: 0 16px;
      }
      .content-area {
        padding: 16px;
      }
      .content-container {
        padding: 20px;
        margin-bottom: 90px;
      }
      .bottom-bar {
        position: fixed;
        padding: 0 16px;
      }
    }
  </style>
</head>
<body>

  <!-- Sidebar -->
  <div class="sidebar">
    <div class="sidebar-header">
      <div class="codelab-title"><%= @codelab[:title] %></div>
      <div class="doc-switcher">
        <a href="/codelab" class="doc-tab <%= @active_doc == 'codelab' ? 'active' : '' %>">📖 Codelab</a>
        <a href="/constitution" class="doc-tab <%= @active_doc == 'constitution' ? 'active' : '' %>">📜 Constitution</a>
        <a href="/skeleton" class="doc-tab <%= @active_doc == 'skeleton' ? 'active' : '' %>">🦴 Skeleton</a>
      </div>
    </div>
    <div class="sidebar-menu">
      <% @codelab[:steps].each_with_index do |step, idx| %>
        <a href="#<%= idx %>" class="sidebar-item" id="sidebar-item-<%= idx %>">
          <span class="step-num"><%= idx + 1 %></span>
          <span><%= step[:title] %></span>
        </a>
      <% end %>
    </div>
  </div>

  <!-- Main layout -->
  <div class="main-layout">
    
    <!-- Top Header -->
    <div class="top-header">
      <div class="current-step-title" id="header-step-title">Overview</div>
      <div class="metadata-info">
        <% if @codelab[:frontmatter]['author'] %>
          <div class="metadata-item">
            <span>By: <strong><%= @codelab[:frontmatter]['author'] %></strong></span>
          </div>
        <% end %>
        <% if @codelab[:frontmatter]['duration'] %>
          <div class="metadata-item">
            <span class="badge">⏱️ <%= @codelab[:frontmatter]['duration'] %> mins</span>
          </div>
        <% end %>
      </div>
    </div>

    <!-- Main Content Area -->
    <div class="content-area" id="main-content">
      <div class="content-container">
        
        <!-- Rendered Steps -->
        <% @codelab[:steps].each_with_index do |step, idx| %>
          <div class="step-content" id="step-<%= idx %>" style="display: none;">
            <h1><%= idx + 1 %>. <%= step[:title] %></h1>
            
            <% if idx == 0 && (@codelab[:frontmatter] && @codelab[:frontmatter].any?) %>
              <div class="metadata-card">
                <h3>Workshop Details</h3>
                <div class="metadata-grid">
                  <% @codelab[:frontmatter].each do |k, v| %>
                    <% next if k == 'title' %>
                    <div>
                      <div class="meta-lbl"><%= k %></div>
                      <div class="meta-val">
                        <% if v.is_a?(Array) %>
                          <%= v.join(', ') %>
                        <% else %>
                          <%= v %>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>

            <%= render_markdown(step[:content]) %>
          </div>
        <% end %>

      </div>
    </div>

    <!-- Bottom Navigation Bar -->
    <div class="bottom-bar">
      <a href="#" class="btn btn-secondary" id="prev-btn">BACK</a>
      <span class="progress-text" id="progress-indicator">Step 1 of <%= @codelab[:steps].size %></span>
      <a href="#" class="btn btn-primary" id="next-btn">NEXT</a>
    </div>

  </div>

  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-ruby.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-bash.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-yaml.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-terraform.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/mermaid@10.9.0/dist/mermaid.min.js"></script>
  
  <script>
    if (typeof mermaid !== 'undefined') {
      mermaid.initialize({
        startOnLoad: false,
        theme: 'neutral',
        securityLevel: 'loose',
        fontFamily: "'Google Sans', 'Roboto', sans-serif"
      });
    }

    function renderMermaid(containerElement) {
      if (typeof mermaid === 'undefined') return;
      const scope = containerElement || document;
      const codeBlocks = scope.querySelectorAll('pre code.language-mermaid, pre.language-mermaid code, pre code');
      let foundMermaid = false;

      codeBlocks.forEach(codeBlock => {
        const pre = codeBlock.closest('pre');
        if (!pre || pre.dataset.mermaidProcessed) return;

        const text = codeBlock.textContent.trim();
        const isMermaid = codeBlock.classList.contains('language-mermaid') ||
                          pre.classList.contains('language-mermaid') ||
                          text.startsWith('flowchart ') ||
                          text.startsWith('sequenceDiagram') ||
                          text.startsWith('graph ') ||
                          text.startsWith('erDiagram') ||
                          text.startsWith('classDiagram') ||
                          text.startsWith('stateDiagram') ||
                          text.startsWith('pie');

        if (isMermaid) {
          const wrapper = document.createElement('div');
          wrapper.className = 'mermaid-container';
          const mermaidDiv = document.createElement('div');
          mermaidDiv.className = 'mermaid';
          mermaidDiv.textContent = text;
          wrapper.appendChild(mermaidDiv);

          pre.dataset.mermaidProcessed = 'true';
          pre.parentNode.replaceChild(wrapper, pre);
          foundMermaid = true;
        }
      });

      if (foundMermaid || scope.querySelector('.mermaid:not([data-processed="true"])')) {
        try {
          mermaid.run();
        } catch (err) {
          console.warn('Mermaid rendering notice:', err);
        }
      }
    }

    function showStep() {
      let hash = window.location.hash;
      if (!hash || !hash.match(/^#\d+$/)) {
        hash = '#0';
      }
      
      let stepIndex = parseInt(hash.substring(1));
      let stepElement = document.getElementById('step-' + stepIndex);
      
      if (!stepElement) {
        hash = '#0';
        stepIndex = 0;
        stepElement = document.getElementById('step-0');
      }
      
      document.querySelectorAll('.step-content').forEach(el => {
        el.style.display = 'none';
      });
      
      if (stepElement) {
        stepElement.style.display = 'block';
        let stepHeader = stepElement.querySelector('h1');
        if (stepHeader) {
          let titleText = stepHeader.innerText.replace(/^\d+\.\s+/, '');
          document.getElementById('header-step-title').innerText = titleText;
        }
        renderMermaid(stepElement);
      }
      
      document.querySelectorAll('.sidebar-item').forEach((el, idx) => {
        el.classList.remove('active');
        if (idx < stepIndex) {
          el.classList.add('completed');
        } else {
          el.classList.remove('completed');
        }
      });
      
      let activeSidebarItem = document.getElementById('sidebar-item-' + stepIndex);
      if (activeSidebarItem) {
        activeSidebarItem.classList.add('active');
        activeSidebarItem.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
      }
      
      let prevButton = document.getElementById('prev-btn');
      if (stepIndex > 0) {
        prevButton.style.visibility = 'visible';
        prevButton.href = '#' + (stepIndex - 1);
      } else {
        prevButton.style.visibility = 'hidden';
      }
      
      let nextButton = document.getElementById('next-btn');
      let totalSteps = document.querySelectorAll('.step-content').length;
      
      if (stepIndex < totalSteps - 1) {
        nextButton.style.visibility = 'visible';
        nextButton.href = '#' + (stepIndex + 1);
        nextButton.innerText = 'NEXT';
      } else {
        nextButton.style.visibility = 'visible';
        nextButton.href = '#0';
        nextButton.innerText = 'RESTART 🔄';
      }
      
      document.getElementById('progress-indicator').innerText = 'Step ' + (stepIndex + 1) + ' of ' + totalSteps;
      document.getElementById('main-content').scrollTop = 0;
      
      if (window.Prism) {
        Prism.highlightAll();
      }
    }
    
    function processBlockquotes() {
      document.querySelectorAll('blockquote').forEach(bq => {
        const text = bq.innerText || '';
        if (text.includes('💡') || text.includes('ℹ️') || text.includes('🟢') || text.includes('[!NOTE]') || text.includes('[!TIP]')) {
          bq.classList.add('info-box', 'positive');
        } else if (text.includes('⚠️') || text.includes('🟡') || text.includes('[!WARNING]') || text.includes('[!IMPORTANT]')) {
          bq.classList.add('info-box', 'warning');
        } else if (text.includes('🛑') || text.includes('🚨') || text.includes('🔴') || text.includes('[!CAUTION]')) {
          bq.classList.add('info-box', 'negative');
        } else {
          bq.classList.add('info-box', 'positive');
        }
        
        bq.innerHTML = bq.innerHTML
          .replace(/\[!NOTE\]/gi, '<strong>Note:</strong>')
          .replace(/\[!TIP\]/gi, '<strong>Tip:</strong>')
          .replace(/\[!WARNING\]/gi, '<strong>Warning:</strong>')
          .replace(/\[!IMPORTANT\]/gi, '<strong>Important:</strong>')
          .replace(/\[!CAUTION\]/gi, '<strong>Caution:</strong>');
      });
    }

    window.addEventListener('hashchange', showStep);
    document.addEventListener('DOMContentLoaded', () => {
      processBlockquotes();
      showStep();
    });
  </script>
</body>
</html>
