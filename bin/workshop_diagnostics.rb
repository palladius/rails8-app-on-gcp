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

  # Strict Anti-Legacy Check: PROJECT_ID is forbidden, must use GOOGLE_CLOUD_PROJECT
  if env_vars.key?("PROJECT_ID")
    puts "❌ [ERROR] Found deprecated variable 'PROJECT_ID' in #{env_file}!".red
    puts "   👉 Nei nuovi standard di Google Cloud / Terraform / Pulumi, 'PROJECT_ID' è deprecato."
    puts "   👉 Rinomina 'PROJECT_ID' in 'GOOGLE_CLOUD_PROJECT' nel tuo file .env!"
    errors_count += 1
  end

  # Strict Anti-Legacy Check: GCLOUD_USER is forbidden, must use GOOGLE_CLOUD_ACCOUNT
  if env_vars.key?("GCLOUD_USER")
    puts "❌ [ERROR] Found deprecated variable 'GCLOUD_USER' in #{env_file}!".red
    puts "   👉 'GCLOUD_USER' è deprecato. Lo standard ufficiale è 'GOOGLE_CLOUD_ACCOUNT'."
    puts "   👉 Rinomina 'GCLOUD_USER' in 'GOOGLE_CLOUD_ACCOUNT' nel tuo file .env!"
    errors_count += 1
  end
else
  puts "⚠️  [ENV] No .env file found at repository root!".yellow
  puts "   👉 Please run: cp .env.dist .env && vim .env"
  warnings_count += 1
end

puts "\n--- 👤 1. Checking Google Cloud & Admin Identity (GOOGLE_CLOUD_ACCOUNT) ---".bold
# GOOGLE_CLOUD_ACCOUNT is primary for billing, terraform, IAM, ADC, and IAP; ADMIN_EMAIL defaults to it.
gcp_account = env_vars["GOOGLE_CLOUD_ACCOUNT"] || env_vars["GOOGLE_CLOUD_EMAIL"] || env_vars["GCP_EMAIL"] ||
              ENV["GOOGLE_CLOUD_ACCOUNT"] || ENV["GOOGLE_CLOUD_EMAIL"] || ENV["GCP_EMAIL"]
admin_email = env_vars["ADMIN_EMAIL"] || ENV["ADMIN_EMAIL"]

# Auto-discover GCP account from gcloud if omitted in .env
active_gcloud_account = `gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null`.strip
if gcp_account.to_s.strip.empty? || gcp_account == "your-personal-email@gmail.com" || gcp_account == "your-email@gmail.com"
  if !active_gcloud_account.empty?
    gcp_account = active_gcloud_account
    puts "ℹ️  GOOGLE_CLOUD_ACCOUNT not customized in .env; detected active account from gcloud: #{gcp_account}".blue
  else
    puts "❌ [ERROR] GOOGLE_CLOUD_ACCOUNT is missing or placeholder in .env and gcloud has no active logged-in account!".red
    puts "   👉 Un account Google valido è OBBLIGATORIO per: risorse billable, Terraform e IAM/IAP."
    puts "   👉 Set GOOGLE_CLOUD_ACCOUNT=\"yourname@gmail.com\" in .env or run: gcloud auth login"
    errors_count += 1
  end
else
  puts "✅ GOOGLE_CLOUD_ACCOUNT configured: #{gcp_account}".green
end

# Admin email resolution: defaults strictly to GOOGLE_CLOUD_ACCOUNT
effective_admin = admin_email.to_s.strip.empty? ? gcp_account : admin_email
if effective_admin.to_s.strip.empty?
  puts "❌ [ERROR] ADMIN_EMAIL could not be resolved from GOOGLE_CLOUD_ACCOUNT or .env!".red
  errors_count += 1
else
  puts "✅ Blog Admin User defaults to: #{effective_admin}".green
end

# Mandatory Warning: Non-Google/Gmail account
if !gcp_account.to_s.strip.empty?
  unless gcp_account.end_with?("@gmail.com") || gcp_account.end_with?("@google.com")
    puts "⚠️  [WARNING] GOOGLE_CLOUD_ACCOUNT (#{gcp_account}) is not a @gmail.com or @google.com address!".yellow
    puts "   Attenzione: Se usi un account non Google/Gmail ti apri a problemi critici con GCP:"
    puts "   - Attivazione e linking account di fatturazione (Billable resources)"
    puts "   - Esecuzione di `terraform apply` (IAM policy bindings per user:email)"
    puts "   - Zero-Trust Identity-Aware Proxy (IAP) e matching utente."
    warnings_count += 1
  else
    puts "✅ Google Account verified: #{gcp_account} (Ready for Billing, Terraform, IAM & IAP)".green
  end
end

# Warning if someone explicitly overrode ADMIN_EMAIL to be different
if !admin_email.to_s.strip.empty? && !gcp_account.to_s.strip.empty? && admin_email.strip.downcase != gcp_account.strip.downcase
  puts "⚠️  [WARNING] ADMIN_EMAIL (#{admin_email}) and GOOGLE_CLOUD_ACCOUNT (#{gcp_account}) differ!".yellow
  puts "   Se usi 2 email diverse puoi avere problemi con Mailpit, single sign-on IAP e matching utente."
  warnings_count += 1
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

  # Check gcloud authentication & multi-account support
  credentialed_accounts = `gcloud auth list --format="value(account)" 2>/dev/null`.strip.split("\n").map(&:strip).reject(&:empty?)
  active_account = `gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null`.strip

  if credentialed_accounts.empty?
    puts "❌ [ERROR] No gcloud accounts logged in!".red
    puts "   👉 Run: gcloud auth login"
    errors_count += 1
  else
    puts "✅ gcloud logged in as: #{active_account}".green
    if credentialed_accounts.size > 1
      puts "ℹ️  Multi-login detected: #{credentialed_accounts.size} accounts available (#{credentialed_accounts.join(', ')})".cyan
    end

    # If GOOGLE_CLOUD_ACCOUNT is specified in .env, verify it matches active or is in credentialed list
    if !gcp_account.to_s.strip.empty?
      if active_account.downcase != gcp_account.downcase
        if credentialed_accounts.map(&:downcase).include?(gcp_account.downcase)
          puts "⚠️  [WARNING] gcloud active account is '#{active_account}', but .env specifies '#{gcp_account}'!".yellow
          puts "   👉 To switch active gcloud account, run:"
          puts "      gcloud config set account #{gcp_account}"
          warnings_count += 1
        else
          puts "❌ [ERROR] .env specifies GOOGLE_CLOUD_ACCOUNT='#{gcp_account}', but it is NOT logged in via gcloud!".red
          puts "   Available accounts: #{credentialed_accounts.join(', ')}"
          puts "   👉 Run: gcloud auth login #{gcp_account}"
          errors_count += 1
        end
      end
    end
  end

  # Check Billing Enabled (MANDATORY GATE!)
  print "   🔍 Verifying GCP Billing status... "
  billing_account_flag = (!gcp_account.to_s.strip.empty? && credentialed_accounts.map(&:downcase).include?(gcp_account.downcase)) ? "--account=#{gcp_account}" : ""
  billing_cmd = "gcloud beta billing projects describe #{project_id} #{billing_account_flag} --format='value(billingEnabled)' 2>/dev/null"
  billing_enabled, _stderr, status = Open3.capture3(billing_cmd)
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
