#!/usr/bin/env ruby
# frozen_string_literal: true

# bin/sync_devsite_codelab.rb
# Synchronizes workshop/CODELAB.md (GitHub source of truth) with the Google3 DevSite Codelab
# (index.lab.md) if a local CitC workspace is present, preserving DevSite frontmatter & image paths.

REPO_ROOT = File.expand_path("..", __dir__)
CODELAB_MD = File.join(REPO_ROOT, "workshop", "CODELAB.md")
DEFAULT_DEVSITE_PATH = "/google/src/cloud/ricc/fl100-friction-log-feedback/google3/third_party/devsite/codelabs/en/codelabs/rails8-on-google-cloud/index.lab.md"

devsite_path = ENV.fetch("DEVSITE_CODELAB_PATH", DEFAULT_DEVSITE_PATH)

unless File.exist?(devsite_path)
  puts "ℹ️  Google3 DevSite path not found (#{devsite_path}) — skipping DevSite sync."
  exit 0
end

codelab_content = File.read(CODELAB_MD)
devsite_content = File.read(devsite_path)

# Keep DevSite frontmatter up to `# Rails 8 on Google Cloud`
header_match = devsite_content.match(/\A(.*?)(?=^# Rails 8 on Google Cloud)/m)
frontmatter = header_match ? header_match[1] : ""

body = codelab_content.sub(/\A.*?^(?=# Rails 8 on Google Cloud)/m, "")
# Rewrite relative image paths from GitHub Codelab to DevSite Codelab paths
body = body.gsub(%r{\(assets/images/([^)]+)\)}, '(/codelabs/rails8-on-google-cloud/img/\1)')
# Convert `<details><summary>...</summary>...</details>` to standard markdown sections for DevSite parser compatibility
body = body.gsub(%r{<details>\s*<summary><strong>(.*?)</strong></summary>(.*?)</details>}m) do
  "#### #{Regexp.last_match(1)}\n#{Regexp.last_match(2)}"
end

File.write(devsite_path, "#{frontmatter}#{body}")
puts "✅ Synchronized workshop/CODELAB.md (v#{File.read(File.join(REPO_ROOT, 'workshop/CODELAB_VERSION')).strip}) -> #{devsite_path}"
