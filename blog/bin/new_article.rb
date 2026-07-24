#!/usr/bin/env ruby

require "optparse"

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: bin/rails runner bin/new_article.rb [options]"

  opts.on("-a", "--article PATH", "Path to markdown file or '-' for stdin") do |a|
    options[:article] = a
  end

  opts.on("-i", "--image PATH", "Path to image to attach") do |i|
    options[:image] = i
  end

  opts.on("-t", "--title TITLE", "Optional title to override the markdown H1 or filename") do |t|
    options[:title] = t
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

unless options[:article]
  warn "Fatal: --article is required."
  exit 1
end

body = ""
title = nil

if options[:article] == "-"
  body = $stdin.read
  title = "Untitled Article"
else
  unless File.exist?(options[:article])
    warn "Fatal: Article file '#{options[:article]}' not found."
    exit 1
  end
  body = File.read(options[:article])
  title = File.basename(options[:article], ".*").titleize
end

# Extract title from H1 if present
if body.match(/^#\s+(.+)$/)
  title = $1.strip
end

# Override with --title option if provided
title = options[:title] if options[:title]

post = Post.find_by(title: title)

if post
  post.update!(body: body)
  post.comments.create!(content: "Automatically updated via CLI at #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}")
  puts "Updated existing post: '#{title}'"
else
  post = Post.create!(title: title, body: body)
  puts "Created new post: '#{title}'"
end

if options[:image]
  if File.exist?(options[:image])
    post.cover_image.attach(io: File.open(options[:image]), filename: File.basename(options[:image]))
    puts "Attached image: #{options[:image]}"
  else
    warn "Warning: Image file '#{options[:image]}' not found. Skipping attachment."
  end
end
