#!/usr/bin/env ruby
# frozen_string_literal: true

# bin/workshop_uat.rb
# Fast User Acceptance Testing (UAT) harness for Workshop Steps
#
# Flow:
# 1. Clones from local repository into a temporary directory (fast & isolated, no network needed).
# 2. Applies the target Step (Time-Machine rewind or baseline configuration).
# 3. Executes the step-specific automated evaluation (`bin/workshop_eval.rb <step>`).
# 4. Cleans up temporary clone.

require "tmpdir"
require "fileutils"
require "open3"
require "optparse"

class String
  def red; "\e[31m#{self}\e[0m"; end
  def green; "\e[32m#{self}\e[0m"; end
  def yellow; "\e[33m#{self}\e[0m"; end
  def cyan; "\e[36m#{self}\e[0m"; end
  def bold; "\e[1m#{self}\e[0m"; end
end

target_step = ARGV[0] || "1"
keep_dir = ARGV.include?("--keep")

repo_root = File.expand_path("..", __dir__)

puts "\n🦖 =========================================================".cyan
puts "   WORKSHOP STEP FAST UAT HARNESS (`workshop-uat`)".cyan.bold
puts "=========================================================\n".cyan
puts "🎯 Testing Step: #{target_step.bold} in fresh isolated local clone"

tmp_dir = Dir.mktmpdir("rails8-workshop-uat-step-#{target_step}-")
puts "📂 Fresh workspace created at: #{tmp_dir}".yellow

begin
  # 1. Fast local git clone (using file:// avoids network, uses local objects)
  print "📦 Cloning local repository into temporary workspace... "
  _out, err, status = Open3.capture3("git clone --quiet \"#{repo_root}\" \"#{tmp_dir}\"")
  unless status.success?
    puts "FAILED ❌".red
    warn "Git clone error: #{err}".red
    exit 1
  end
  puts "DONE ✅".green

  # 2. Replicate environment secrets (.env) if present in original repo
  local_env = File.join(repo_root, ".env")
  if File.exist?(local_env)
    FileUtils.cp(local_env, File.join(tmp_dir, ".env"))
    puts "🔑 Replicated .env to sandbox workspace".green
  else
    dist_env = File.join(repo_root, ".env.dist")
    if File.exist?(dist_env)
      FileUtils.cp(dist_env, File.join(tmp_dir, ".env"))
      puts "🔑 Copied .env.dist as .env in sandbox workspace".yellow
    end
  end

  # Also copy bundle vendor or config if appropriate to skip re-bundling
  bundle_dir = File.join(repo_root, "blog", "vendor", "bundle")
  if Dir.exist?(bundle_dir)
    target_bundle = File.join(tmp_dir, "blog", "vendor", "bundle")
    FileUtils.mkdir_p(File.dirname(target_bundle))
    # Symlink bundle cache to avoid slow bundle install
    File.symlink(bundle_dir, target_bundle) rescue nil
  end

  local_bundle_config = File.join(repo_root, "blog", ".bundle")
  if Dir.exist?(local_bundle_config)
    FileUtils.cp_r(local_bundle_config, File.join(tmp_dir, "blog", ".bundle"))
  end

  # 3. Apply Step N configuration
  puts "⚙️  Applying Step #{target_step} configuration in sandbox...".cyan
  case target_step.to_s
  when "0", "step-0"
    # Step 0 is clean setup
    puts "   Applying baseline setup (Step 0)"
  when "1", "step-1"
    # Step 1 is pre-flight & terraform kickoff
    puts "   Applying Step 1 (Diagnostics & Terraform setup)"
  when "2", "step-2"
    # Step 2 is local baseline with seeds
    puts "   Applying Step 2 (Local Docker/SQLite baseline)"
  when "3", "step-3"
    # Step 3 is Stateless Cloud Run (rewind 1)
    system("cd \"#{tmp_dir}\" && ruby bin/workshop_time_machine.rb rewind 1 > /dev/null")
    puts "   Rewound to Time-Machine Stage 1 (Stateless SQLite)".green
  when "4", "step-4"
    # Step 4 is GCS Storage (rewind 2)
    system("cd \"#{tmp_dir}\" && ruby bin/workshop_time_machine.rb rewind 2 > /dev/null")
    puts "   Rewound to Time-Machine Stage 2 (GCS Storage)".green
  when "5", "step-5", "6", "step-6", "7", "step-7", "8", "step-8"
    # Full cloud persistence / Gold Standard
    system("cd \"#{tmp_dir}\" && ruby bin/workshop_time_machine.rb restore-gold > /dev/null")
    puts "   Restored to Gold Standard (main)".green
  end

  # 4. Run automated evaluations for Step N inside the sandbox
  puts "🧪 Running EVAL suite for Step #{target_step}...".cyan
  cmd = "ruby bin/workshop_eval.rb #{target_step}"
  
  # Stream output directly so student/developer sees real-time progress
  Dir.chdir(tmp_dir) do
    success = system(cmd)
    if success
      puts "\n🎉 [UAT SUCCESS] Step #{target_step} passed all validations in a clean clone! 🚀".green.bold
    else
      puts "\n❌ [UAT FAILURE] Step #{target_step} failed validations in clean clone!".red.bold
      exit 1 unless keep_dir
    end
  end

ensure
  if keep_dir
    puts "ℹ️  Keeping workspace directory for inspection: #{tmp_dir}".yellow
  else
    FileUtils.rm_rf(tmp_dir)
    puts "🧹 Cleaned up temporary workspace.".cyan
  end
end
