#!/usr/bin/env ruby
# frozen_string_literal: true

# bin/workshop_time_machine.rb
# Zero-Branch Time Machine overlay engine for Rails 8 on GCP Workshop (Issue #23 & #28)

require "fileutils"

action = ARGV[0]
stage_arg = ARGV[1]

repo_root = File.expand_path("..", __dir__)
tm_root = File.join(repo_root, "workshop", "time-machine")

class String
  def red; "\e[31m#{self}\e[0m"; end
  def green; "\e[32m#{self}\e[0m"; end
  def yellow; "\e[33m#{self}\e[0m"; end
  def cyan; "\e[36m#{self}\e[0m"; end
  def bold; "\e[1m#{self}\e[0m"; end
end

def rewind(stage_num, repo_root, tm_root)
  stage_folder = case stage_num.to_s
                 when "1", "stage-1", "stage-1-stateless"
                   "stage-1-stateless"
                 when "2", "stage-2", "stage-2-gcs"
                   "stage-2-gcs"
                 else
                   nil
                 end

  unless stage_folder
    warn "❌ [Time-Machine] Unknown stage '#{stage_num}'. Supported: 1 (stateless), 2 (gcs).".red
    exit 1
  end

  source_dir = File.join(tm_root, stage_folder)
  unless Dir.exist?(source_dir)
    warn "❌ [Time-Machine] Stage directory not found: #{source_dir}".red
    exit 1
  end

  puts "⏳ [Time-Machine] Rewinding configuration to #{stage_folder.bold}...".cyan
  # Copy overlay files under blog/
  source_blog = File.join(source_dir, "blog")
  if Dir.exist?(source_blog)
    FileUtils.cp_r("#{source_blog}/.", File.join(repo_root, "blog"))
    puts "✅ Applied overlay files from #{stage_folder} to blog/".green
    puts "   👉 Modified configuration files: config/database.yml, config/storage.yml, etc."
    puts "   👉 To return to the canonical Gold Standard anytime, run: just workshop-restore-gold"
  end
end

def restore_gold(repo_root)
  puts "👑 [Time-Machine] Restoring repository to Gold Standard (main)...".cyan
  Dir.chdir(repo_root) do
    system("git checkout blog/config/")
  end
  puts "✅ Restored canonical blog/config/ files to git HEAD.".green
end

case action
when "rewind"
  if stage_arg.nil? || stage_arg.empty?
    warn "Usage: bin/workshop_time_machine.rb rewind <stage_number (1 or 2)>".red
    exit 1
  end
  rewind(stage_arg, repo_root, tm_root)
when "restore", "restore-gold"
  restore_gold(repo_root)
else
  warn "Usage: bin/workshop_time_machine.rb [rewind <1|2> | restore-gold]".yellow
  exit 1
end
