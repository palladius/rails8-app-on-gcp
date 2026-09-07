#!/usr/bin/env ruby
# frozen_string_literal: true

# bin/workshop_diagnostics.rb
# Diagnostics Suite for the Rails 8 on GCP Workshop (Issue #24)
# Run via: just workshop-test

require "open3"
require "fileutils"

class String
  def red; "\e[31m#{self}\e[0m"; end
  def green; "\e[32m#{self}\e[0m"; end
  def yellow; "\e[33m#{self}\e[0m"; end
  def blue; "\e[34m#{self}\e[0m"; end
  def cyan; "\e[36m#{self}\e[0m"; end
  def bold; "\e[1m#{self}\e[0m"; end
end

puts "\n🦖 =========================================================".cyan
puts "   RAILS 8 ON GCP WORKSHOP DIAGNOSTICS SUITE (`just workshop-test`)".cyan.bold
puts "=========================================================\n".cyan

errors_count = 0
warnings_count = 0

# 1. Load .env if present
env_file = File.exist?(".env") ? File.expand_path(".env") : File.expand_path("../.env", __dir__)
env_vars = {}
if File.exist?(env_file)
  File.readlines(env_file).each do |line|
    line = line.strip
    next if line.empty? || line.start_with?("#")
    k, v = line.split("=", 2)
    env_vars[k.strip] = v.to_s.strip.gsub(/\A["']|["']\Z/, "") if k
  end
  puts "📄 [ENV] .env file found and parsed (#{env_vars.keys.count} vars)".green
else
  puts "⚠️  [ENV] No .env file found at repository root!".yellow
  puts "   👉 Please run: cp .env.dist .env && vim .env"
  warnings_count += 1
end

puts "\n--- 👤 1. Checking Identity & Admin Email ---".bold
admin_email = env_vars["ADMIN_EMAIL"] || ENV["ADMIN_EMAIL"]
if admin_email.to_s.strip.empty?
  puts "❌ [ERROR] ADMIN_EMAIL is missing in .env!".red
  puts "   👉 Required for creating the initial blog admin user."
  errors_count += 1
else
  puts "✅ ADMIN_EMAIL configured: #{admin_email}".green
  if admin_email.end_with?("@gmail.com") || admin_email.end_with?("@google.com")
    puts "✅ Email provider is Google/Gmail (Recommended for IAP and GCP access)".green
  else
    puts "⚠️  [WARNING] ADMIN_EMAIL is not a @gmail.com or @google.com address!".yellow
    puts "   Recommendation: Using a Gmail address makes IAP and Google Cloud access seamless."
    warnings_count += 1
  end
end

puts "\n--- ☁️  2. Checking Google Cloud Project & Billing ---".bold
project_id = env_vars["GCP_PROJECT_ID"] || env_vars["GOOGLE_CLOUD_PROJECT"] || ENV["GCP_PROJECT_ID"] || ENV["GOOGLE_CLOUD_PROJECT"]
if project_id.to_s.strip.empty? || project_id == "your-gcp-project-id"
  # Attempt to fetch from gcloud
  project_id = `gcloud config get-value project 2>/dev/null`.strip
end

if project_id.empty? || project_id == "(unset)"
  puts "❌ [ERROR] GCP Project ID is not set in .env or gcloud!".red
  puts "   👉 Set GCP_PROJECT_ID in .env or run: gcloud config set project <PROJECT_ID>"
  errors_count += 1
else
  puts "✅ Active GCP Project ID: #{project_id}".green

  # Check gcloud authentication
  active_account = `gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null`.strip
  if active_account.empty?
    puts "❌ [ERROR] No active gcloud account logged in!".red
    puts "   👉 Run: gcloud auth login"
    errors_count += 1
  else
    puts "✅ gcloud logged in as: #{active_account}".green
  end

  # Check Billing Enabled (MANDATORY GATE!)
  print "   🔍 Verifying GCP Billing status... "
  billing_enabled, _stderr, status = Open3.capture3("gcloud beta billing projects describe #{project_id} --format='value(billingEnabled)' 2>/dev/null")
  billing_status = billing_enabled.strip.downcase

  if status.success? && billing_status == "true"
    puts "ACTIVE (Billing is linked!)".green
  else
    puts "INACTIVE or ACCESS DENIED".red
    puts "❌ [ERROR] GCP Billing is NOT enabled on project '#{project_id}'!".red
    puts "   Terraform and Cloud SQL will fail immediately with BillingNotEnabled."
    puts "   👉 Link a billing account or redeem workshop credits here:"
    puts "      https://console.cloud.google.com/billing/linkedaccount?project=#{project_id}"
    errors_count += 1
  end

  # Check Application Default Credentials (ADC for Vertex AI)
  print "   🔍 Checking Application Default Credentials (ADC for Vertex AI)... "
  _token, _err, adc_status = Open3.capture3("gcloud auth application-default print-access-token 2>/dev/null")
  if adc_status.success?
    puts "VALID (Vertex AI ready via ADC)".green
  else
    puts "MISSING".yellow
    puts "⚠️  [WARNING] ADC credentials not found or expired!".yellow
    puts "   👉 Run: gcloud auth application-default login"
    warnings_count += 1
  end
end

puts "\n--- 🔑 3. Checking Rails Secrets & Keys ---".bold
master_key_file = File.expand_path("../blog/config/master.key", __dir__)
master_key_env = env_vars["RAILS_MASTER_KEY"] || ENV["RAILS_MASTER_KEY"]

if File.exist?(master_key_file)
  puts "✅ config/master.key found on disk".green
elsif !master_key_env.to_s.strip.empty?
  puts "✅ RAILS_MASTER_KEY configured in environment".green
else
  puts "⚠️  [WARNING] Neither config/master.key nor RAILS_MASTER_KEY found!".yellow
  puts "   👉 If starting fresh, run: cd blog && bin/rails credentials:edit"
  warnings_count += 1
end

puts "\n--- 🐤 4. Checking Storage & Canary Asset ---".bold
if project_id && !project_id.empty? && project_id != "(unset)"
  bucket_dev = "#{project_id}-activestorage-dev"
  _out, _err, b_status = Open3.capture3("gcloud storage buckets describe gs://#{bucket_dev} 2>/dev/null")
  if b_status.success?
    puts "✅ GCS Bucket gs://#{bucket_dev} exists".green
    # Check canary
    canary_path = "gs://#{bucket_dev}/seeds/gcs_dev_image.jpg"
    _cout, _cerr, c_status = Open3.capture3("gcloud storage ls #{canary_path} 2>/dev/null")
    if c_status.success?
      puts "✅ Canary image found on GCS: #{canary_path}".green
    else
      puts "ℹ️  Canary image not yet uploaded to GCS (normal before Step 1 terraform apply)".cyan
    end
  else
    puts "ℹ️  GCS Bucket gs://#{bucket_dev} not yet created (normal before Step 1 terraform apply)".cyan
  end
end

puts "\n--- 🧭 5. Current Architectural State Telemetry ---".bold
storage_yml = File.expand_path("../blog/config/storage.yml", __dir__)
database_yml = File.expand_path("../blog/config/database.yml", __dir__)

is_gcs = false
if File.exist?(storage_yml)
  content = File.read(storage_yml)
  is_gcs = content.include?("service: GCS") && !content.include?("# service: GCS")
end

is_cloud_sql = false
if File.exist?(database_yml)
  content = File.read(database_yml)
  is_cloud_sql = content.include?("adapter: postgresql") || content.include?("5432")
end

if is_cloud_sql && is_gcs
  puts "Current State: [🔋 CLOUD SQL PERSISTENT] [☁️ GCS SIGNED] (Stage 3: Enterprise Gold Standard)".green.bold
elsif is_gcs
  puts "Current State: [🪫 EPHEMERAL DB] [☁️ GCS SIGNED] (Stage 2: Hybrid Storage Uplift)".yellow.bold
else
  puts "Current State: [🪫 EPHEMERAL DB] [🪣 LOCAL STORAGE] (Stage 1 / Localhost Baseline)".cyan.bold
end

puts "\n=========================================================".cyan
if errors_count > 0
  puts "❌ Diagnostics finished with #{errors_count} error(s) and #{warnings_count} warning(s).".red.bold
  puts "👉 Please resolve the blocking errors above before running Terraform or deploying.\n"
  exit 1
elsif warnings_count > 0
  puts "⚠️  Diagnostics finished with #{warnings_count} warning(s). Environment is mostly ready!".yellow.bold
  puts "👉 You can safely proceed to Step 1.\n"
  exit 0
else
  puts "✨ ALL CHECKS PASSED! Your workshop environment is in pristine shape. 🚀".green.bold
  puts "👉 You are 100% ready for the Rails 8 on GCP Workshop!\n"
  exit 0
end
