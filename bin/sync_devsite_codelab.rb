#!/usr/bin/env ruby
# frozen_string_literal: true

# bin/sync_devsite_codelab.rb
# Synchronizes workshop/CODELAB.md (GitHub source of truth) with an external DevSite Codelab
# export path (via ENV["DEVSITE_CODELAB_PATH"] or workshop/build/devsite/index.lab.md).

require "fileutils"

REPO_ROOT = File.expand_path("..", __dir__)
CODELAB_MD = File.join(REPO_ROOT, "workshop", "CODELAB.md")
DEFAULT_BUILD_PATH = File.join(REPO_ROOT, "workshop", "build", "devsite", "index.lab.md")
DOTENV_PATH = File.join(REPO_ROOT, ".env")

dotenv_devsite_path = nil
if File.exist?(DOTENV_PATH)
  File.readlines(DOTENV_PATH).each do |line|
    if line.strip =~ /\A(?:export\s+)?DEVSITE_CODELAB_PATH=(['"]?)(.+?)\1\s*(?:#.*)?\z/
      dotenv_devsite_path = Regexp.last_match(2).strip
    end
  end
end

external_devsite_path = ENV["DEVSITE_CODELAB_PATH"] || dotenv_devsite_path
target_paths = [DEFAULT_BUILD_PATH]
target_paths << external_devsite_path if external_devsite_path && !external_devsite_path.empty?

codelab_content = File.read(CODELAB_MD)
body = codelab_content.sub(/\A.*?^(?=# Rails 8 on Google Cloud)/m, "")
# Rewrite relative image paths from GitHub Codelab to DevSite Codelab paths
body = body.gsub(%r{\(assets/images/([^)]+)\)}, '(/codelabs/rails8-on-google-cloud/img/\1)')
# Convert `<details><summary>...</summary>...</details>` to standard markdown sections for DevSite parser compatibility
body = body.gsub(%r{<details>\s*<summary><strong>(.*?)</strong></summary>(.*?)</details>}m) do
  "#### #{Regexp.last_match(1)}\n#{Regexp.last_match(2)}"
end

target_paths.uniq.each do |devsite_path|
  FileUtils.mkdir_p(File.dirname(devsite_path))
  frontmatter = ""
  if File.exist?(devsite_path)
    existing = File.read(devsite_path)
    header_match = existing.match(/\A(.*?)(?=^# Rails 8 on Google Cloud)/m)
    frontmatter = header_match ? header_match[1] : ""
  end
  File.write(devsite_path, "#{frontmatter}#{body}")
  puts "✅ Synchronized workshop/CODELAB.md (v#{File.read(File.join(REPO_ROOT, 'workshop/CODELAB_VERSION')).strip}) -> #{devsite_path}"
end
