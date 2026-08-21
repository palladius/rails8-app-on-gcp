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
- Automatic fallback to Step 0 for invalid step hashes.
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
  
  # If still not found, search in the current directory for any *.md file
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
  set :markdown_file, File.expand_path(CLI_OPTIONS[:file])
  
  helpers do
    def render_markdown(text)
      Kramdown::Document.new(text, input: 'GFM', syntax_highlighter: nil).to_html
    end
  end
  
  # Main route: serves the visualizer page
  get '/' do
    file_path = settings.markdown_file
    @codelab = parse_markdown(file_path)
    erb :index
  end
  
  # A2UI JSON endpoint
  get '/a2ui' do
    content_type :json
    file_path = settings.markdown_file
    codelab = parse_markdown(file_path)
    
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

  # Catch-all route to serve local assets (like images) relative to the markdown file
  # or the git root directory.
  get '/*' do |path|
    md_dir = File.dirname(settings.markdown_file)
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
    main_title ||= "Codelab Workshop"
    
    # Split content by H2 headers (##)
    parts = content.split(/^##\s+/)
    steps = []
    
    # Process text before the first H2 (excluding the main title we removed)
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
puts "📖 Serving Codelab file: #{cli_options[:file]}"
puts "💡 Tip: Edit the markdown file and just refresh the browser to see updates instantly!"
puts "Press Ctrl+C to stop the server."
puts "\n"

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
      --header-bg: rgba(255, 255, 255, 0.5);
      --footer-bg: rgba(255, 255, 255, 0.5);
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
      padding: 24px;
      border-bottom: 1px solid var(--border-color);
      background: rgba(255, 255, 255, 0.3);
    }
    
    .codelab-title {
      font-size: 18px;
      font-weight: 500;
      color: var(--heading-color);
      line-height: 1.4;
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
    
    /* Elegant floating card container for Codelab steps */
    .content-container {
      max-width: 800px;
      margin: 0 auto;
      background: rgba(255, 255, 255, 0.7);
      backdrop-filter: blur(16px);
      -webkit-backdrop-filter: blur(16px);
      border: 1px solid rgba(255, 255, 255, 0.45);
      border-radius: 16px;
      padding: 48px;
      box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.05);
      margin-bottom: 100px;
    }
    
    .step-content {
      line-height: 1.6;
      font-size: 16px;
    }
    
    .step-content h1, .step-content h2, .step-content h3 {
      color: var(--heading-color);
      margin-top: 24px;
      margin-bottom: 16px;
      font-weight: 500;
    }
    
    .step-content h2 { font-size: 22px; border-bottom: 1px solid var(--border-color); padding-bottom: 8px; }
    .step-content h3 { font-size: 18px; }
    
    .step-content p {
      margin-bottom: 16px;
    }
    
    .step-content ul, .step-content ol {
      margin-bottom: 16px;
      padding-left: 24px;
    }
    
    .step-content li {
      margin-bottom: 8px;
    }
    
    .step-content code {
      font-family: 'Roboto Mono', Consolas, Monaco, monospace;
      background-color: rgba(0, 0, 0, 0.05);
      padding: 2px 6px;
      border-radius: 4px;
      font-size: 14px;
    }
    
    .step-content pre code {
      background-color: transparent;
      padding: 0;
      border-radius: 0;
    }
    
    .step-content pre {
      margin-bottom: 24px;
      border-radius: 8px;
      overflow: hidden;
    }
    
    .step-content img {
      max-width: 100%;
      height: auto;
      border-radius: 8px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.12), 0 1px 2px rgba(0,0,0,0.24);
      margin: 16px 0;
      display: block;
    }
    
    /* Info box styling */
    .info-box {
      border-left-width: 4px;
      border-left-style: solid;
      padding: 16px 20px;
      margin: 24px 0;
      border-radius: 0 8px 8px 0;
    }
    
    .info-box p:last-child {
      margin-bottom: 0;
    }
    
    .info-box.positive {
      background-color: rgba(230, 244, 234, 0.7);
      border-left-color: #137333;
    }
    
    .info-box.warning {
      background-color: rgba(254, 247, 224, 0.7);
      border-left-color: #b06000;
    }
    
    .info-box.negative {
      background-color: rgba(252, 232, 230, 0.7);
      border-left-color: #c5221f;
    }
    
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
    
    .btn-primary {
      background-color: var(--primary-color);
      color: #ffffff;
      border: none;
    }
    
    .btn-primary:hover {
      background-color: var(--primary-hover);
    }
    
    .btn-secondary {
      background: rgba(255, 255, 255, 0.6);
      backdrop-filter: blur(5px);
      color: var(--primary-color);
      border: 1px solid var(--border-color);
    }
    
    .btn-secondary:hover {
      background: rgba(248, 249, 250, 0.8);
    }
    
    .progress-text {
      font-size: 14px;
      color: #5f6368;
    }
    
    /* Ribbon/Badge style */
    .badge {
      display: inline-block;
      padding: 4px 8px;
      background-color: rgba(232, 240, 254, 0.6);
      color: #1a73e8;
      border-radius: 4px;
      font-size: 12px;
      font-weight: 500;
    }
    
    /* Key/Value block for Frontmatter metadata card */
    .metadata-card {
      background: rgba(248, 249, 250, 0.6);
      border: 1px solid var(--border-color);
      border-radius: 8px;
      padding: 20px;
      margin-bottom: 24px;
    }
    
    .metadata-card h3 {
      margin-top: 0 !important;
      margin-bottom: 12px !important;
      font-size: 16px;
      font-weight: 500;
    }
    
    .metadata-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
      gap: 16px;
    }
    
    .meta-val {
      font-weight: 500;
      color: var(--heading-color);
    }
    
    .meta-lbl {
      font-size: 12px;
      color: #5f6368;
      text-transform: uppercase;
      margin-bottom: 4px;
    }
  </style>
</head>
<body>

  <!-- Sidebar -->
  <div class="sidebar">
    <div class="sidebar-header">
      <div class="codelab-title"><%= @codelab[:title] %></div>
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
      <div class="current-step-title" id="header-step-title">Introduction</div>
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
            
            <!-- If overview and we have metadata, show a pretty card -->
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
  
  <script>
    // Detailed JavaScript to manage step navigation client-side, documented for 13yo as requested 🦖
    
    // This function runs every time the page URL hash changes (e.g. from #1 to #2) or on load
    function showStep() {
      // 1. Get the current hash from the browser URL, defaulting to #0 (first step) if empty
      let hash = window.location.hash;
      if (!hash || !hash.match(/^#\d+$/)) {
        hash = '#0';
      }
      
      // 2. Extract the numeric index from the hash (e.g. "#3" -> 3)
      let stepIndex = parseInt(hash.substring(1));
      
      // 3. Find the HTML container for this step
      let stepElement = document.getElementById('step-' + stepIndex);
      
      // 4. Fallback check: if the step element doesn't exist (e.g. user went to #999), go to step 0
      if (!stepElement) {
        hash = '#0';
        stepIndex = 0;
        stepElement = document.getElementById('step-0');
      }
      
      // 5. Hide all step content sections
      document.querySelectorAll('.step-content').forEach(el => {
        el.style.display = 'none';
      });
      
      // 6. Show the currently active step section
      if (stepElement) {
        stepElement.style.display = 'block';
        
        // Update the top header's title to match the active step title
        let stepHeader = stepElement.querySelector('h1');
        if (stepHeader) {
          // Remove the "X. " prefix from header title for top bar display
          let titleText = stepHeader.innerText.replace(/^\d+\.\s+/, '');
          document.getElementById('header-step-title').innerText = titleText;
        }
      }
      
      // 7. Update sidebar navigation styles
      document.querySelectorAll('.sidebar-item').forEach((el, idx) => {
        // Clear active class
        el.classList.remove('active');
        
        // Add "completed" class to all steps prior to current step, so the user knows progress
        if (idx < stepIndex) {
          el.classList.add('completed');
        } else {
          el.classList.remove('completed');
        }
      });
      
      // Highlight the active step in the sidebar
      let activeSidebarItem = document.getElementById('sidebar-item-' + stepIndex);
      if (activeSidebarItem) {
        activeSidebarItem.classList.add('active');
        
        // Ensure the active item is visible in the scrollable sidebar area
        activeSidebarItem.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
      }
      
      // 8. Configure the BACK button
      let prevButton = document.getElementById('prev-btn');
      if (stepIndex > 0) {
        prevButton.style.visibility = 'visible';
        prevButton.href = '#' + (stepIndex - 1);
      } else {
        // Hide the BACK button on the very first page
        prevButton.style.visibility = 'hidden';
      }
      
      // 9. Configure the NEXT button
      let nextButton = document.getElementById('next-btn');
      let totalSteps = document.querySelectorAll('.step-content').length;
      
      if (stepIndex < totalSteps - 1) {
        nextButton.style.visibility = 'visible';
        nextButton.href = '#' + (stepIndex + 1);
        nextButton.innerText = 'NEXT';
      } else {
        // On the final page, show 'RESTART' and link to step 0
        nextButton.style.visibility = 'visible';
        nextButton.href = '#0'; // Wrap back to step 0
        nextButton.innerText = 'RESTART 🔄';
      }
      
      // 10. Update the progress indicator text (e.g. "Step 3 of 8")
      document.getElementById('progress-indicator').innerText = 'Step ' + (stepIndex + 1) + ' of ' + totalSteps;
      
      // 11. Scroll the main content window back to top so user starts reading from the top
      document.getElementById('main-content').scrollTop = 0;
      
      // 12. Run Prism code block syntax highlighter for the new content
      if (window.Prism) {
        Prism.highlightAll();
      }
    }
    
    // Process markdown blockquotes and turn them into styled Google Codelab info-boxes!
    function processBlockquotes() {
      document.querySelectorAll('blockquote').forEach(bq => {
        const text = bq.innerText || '';
        
        // Color code based on emojis or github alert notation
        if (text.includes('💡') || text.includes('ℹ️') || text.includes('🟢') || text.includes('[!NOTE]') || text.includes('[!TIP]')) {
          bq.classList.add('info-box', 'positive');
        } else if (text.includes('⚠️') || text.includes('🟡') || text.includes('[!WARNING]') || text.includes('[!IMPORTANT]')) {
          bq.classList.add('info-box', 'warning');
        } else if (text.includes('🛑') || text.includes('🚨') || text.includes('🔴') || text.includes('[!CAUTION]')) {
          bq.classList.add('info-box', 'negative');
        } else {
          bq.classList.add('info-box', 'positive'); // Default fallback
        }
        
        // Clean up the github alert markdown tags if present
        bq.innerHTML = bq.innerHTML
          .replace(/\[!NOTE\]/gi, '<strong>Note:</strong>')
          .replace(/\[!TIP\]/gi, '<strong>Tip:</strong>')
          .replace(/\[!WARNING\]/gi, '<strong>Warning:</strong>')
          .replace(/\[!IMPORTANT\]/gi, '<strong>Important:</strong>')
          .replace(/\[!CAUTION\]/gi, '<strong>Caution:</strong>');
      });
    }

    // Attach listeners for hash changes and load events
    window.addEventListener('hashchange', showStep);
    
    document.addEventListener('DOMContentLoaded', () => {
      processBlockquotes();
      showStep();
    });
  </script>
</body>
</html>
