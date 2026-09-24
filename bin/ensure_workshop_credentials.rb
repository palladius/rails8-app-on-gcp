#!/usr/bin/env ruby
# frozen_string_literal: true

# bin/ensure_workshop_credentials.rb
# Ensures transactional consistency between:
# 1. blog/config/master.key (32-char hex key, never dummy)
# 2. blog/config/credentials.yml.enc (encrypted with that exact master.key, never left with SAMPLE_APP_CREDENTIALS MD5)
# 3. Google Cloud Secret Manager 'rails-master-key' (if sync_gcp=true and secret exists)

require "digest"
require "securerandom"
require "openssl"
require "base64"
require "fileutils"
require "time"
require "open3"

module WorkshopCredentialsManager
  DUMMY_KEY = "0123456789abcdef0123456789abcdef"
  # MD5 of the original sample app blog/config/credentials.yml.enc shipped in the repo
  SAMPLE_APP_CREDENTIALS = "7b856d06f492f293bea59a5323150d8c"
  SAMPLE_APP_CREDENTIALS_MD5 = SAMPLE_APP_CREDENTIALS
  GENESIS_CREATORS_CREDENTIALS_MD5 = SAMPLE_APP_CREDENTIALS
  WORKSHOP_FILE_MD5_EMI_RICC = SAMPLE_APP_CREDENTIALS

  REPO_ROOT = File.expand_path("..", __dir__)
  BLOG_DIR = File.join(REPO_ROOT, "blog")
  MASTER_KEY_PATH = File.join(BLOG_DIR, "config", "master.key")
  CREDENTIALS_PATH = File.join(BLOG_DIR, "config", "credentials.yml.enc")

  module_function

  def valid_hex_key?(key)
    return false if key.nil?
    cleaned = key.strip
    cleaned.length == 32 && cleaned != DUMMY_KEY && cleaned.match?(/\A[0-9a-f]{32}\z/i)
  end

  def maintainer_credentials_file?(path = CREDENTIALS_PATH)
    return false unless File.exist?(path)
    Digest::MD5.file(path).hexdigest == SAMPLE_APP_CREDENTIALS
  end

  # Pure-Ruby compatible Rails ActiveSupport::MessageEncryptor (aes-128-gcm) verifier & writer
  # Rails 7.1/8.0 default encrypted configuration uses AES-128-GCM with 16-byte raw key (from 32-char hex)
  def can_decrypt_credentials?(hex_key, credentials_path = CREDENTIALS_PATH)
    return false unless valid_hex_key?(hex_key) && File.exist?(credentials_path)
    return false if maintainer_credentials_file?(credentials_path) && ENV["ALLOW_MAINTAINER_KEY"] != "1"

    raw_content = File.read(credentials_path).strip
    parts = raw_content.split("--")
    return false unless parts.size == 3

    encrypted_data, iv, auth_tag = parts.map { |p| Base64.strict_decode64(p) }
    return false unless auth_tag.bytesize == 16

    cipher = OpenSSL::Cipher.new("aes-128-gcm")
    cipher.decrypt
    cipher.key = [hex_key.strip].pack("H*")
    cipher.iv = iv
    cipher.auth_tag = auth_tag
    cipher.auth_data = ""
    cipher.update(encrypted_data) + cipher.final
    true
  rescue StandardError
    false
  end

  # Writes a valid Rails 8 credentials.yml.enc encrypted with the given 32-char hex master key.
  # Strictly isolated to `credentials_path` (never touches real repo files when testing in tmpdir — fixes C4).
  def write_encrypted_credentials!(hex_key, credentials_path = CREDENTIALS_PATH)
    raise ArgumentError, "Invalid 32-char hex master key" unless valid_hex_key?(hex_key)

    yaml_payload = <<~YAML
      # Generated automatically for Rails 8 on GCP Workshop
      secret_key_base: #{SecureRandom.hex(64)}
      workshop:
        generated_at: "#{Time.now.utc.iso8601}"
    YAML

    FileUtils.mkdir_p(File.dirname(credentials_path))
    cipher = OpenSSL::Cipher.new("aes-128-gcm")
    cipher.encrypt
    cipher.key = [hex_key.strip].pack("H*")
    iv = cipher.random_iv
    cipher.iv = iv
    cipher.auth_data = ""
    serialized = Marshal.dump(yaml_payload)
    encrypted_data = cipher.update(serialized) + cipher.final
    auth_tag = cipher.auth_tag
    encoded = [encrypted_data, iv, auth_tag].map { |p| Base64.strict_encode64(p) }.join("--")
    File.write(credentials_path, "#{encoded}\n")
    true
  end

  def fetch_gcp_secret_key(project_id = nil)
    project_id ||= ENV["GOOGLE_CLOUD_PROJECT"]
    if project_id.to_s.strip.empty?
      project_id = `gcloud config get-value project 2>/dev/null`.strip
    end
    return nil if project_id.empty? || project_id == "(unset)"

    out, err, status = Open3.capture3(
      "gcloud", "secrets", "versions", "access", "latest",
      "--secret=rails-master-key", "--project=#{project_id}"
    )
    unless status.success?
      warn "[Credentials] gcloud secrets versions access failed: #{err.strip}" if ENV["VERBOSE"] == "1"
      return nil
    end
    candidate = out.strip
    valid_hex_key?(candidate) ? candidate : nil
  rescue StandardError => e
    warn "[Credentials] fetch_gcp_secret_key error: #{e.message}" if ENV["VERBOSE"] == "1"
    nil
  end

  def push_gcp_secret_key(hex_key, project_id = nil)
    project_id ||= ENV["GOOGLE_CLOUD_PROJECT"]
    if project_id.to_s.strip.empty?
      project_id = `gcloud config get-value project 2>/dev/null`.strip
    end
    return false if project_id.empty? || project_id == "(unset)"

    _desc, err, desc_status = Open3.capture3(
      "gcloud", "secrets", "describe", "rails-master-key", "--project=#{project_id}"
    )
    unless desc_status.success?
      warn "[Credentials] rails-master-key not yet created in GCP: #{err.strip}" if ENV["VERBOSE"] == "1"
      return false
    end

    current_gcp = fetch_gcp_secret_key(project_id)
    return true if current_gcp == hex_key.strip

    Open3.popen3("gcloud", "secrets", "versions", "add", "rails-master-key", "--data-file=-", "--project=#{project_id}") do |stdin, _stdout, _stderr, wait_thr|
      stdin.write(hex_key.strip)
      stdin.close
      wait_thr.value.success?
    end
  rescue StandardError => e
    warn "[Credentials] push_gcp_secret_key error: #{e.message}" if ENV["VERBOSE"] == "1"
    false
  end

  alias_method :can_decrypt?, :can_decrypt_credentials?

  # Read-only diagnostic check (never mutates files — fixes M2)
  def check(repo_root: REPO_ROOT)
    master_key_path = File.join(repo_root, "blog", "config", "master.key")
    credentials_path = File.join(repo_root, "blog", "config", "credentials.yml.enc")
    local_key = File.exist?(master_key_path) ? File.read(master_key_path).strip : nil
    is_sample_md5 = maintainer_credentials_file?(credentials_path)
    paired = valid_hex_key?(local_key) && !is_sample_md5 && can_decrypt_credentials?(local_key, credentials_path)
    {
      status: paired ? :ok : :needs_setup,
      has_valid_local_key: valid_hex_key?(local_key),
      is_sample_app_md5: is_sample_md5,
      can_decrypt: paired
    }
  end

  def ensure!(repo_root: REPO_ROOT, sync_gcp: false, quiet: false)
    master_key_path = File.join(repo_root, "blog", "config", "master.key")
    credentials_path = File.join(repo_root, "blog", "config", "credentials.yml.enc")
    local_key = File.exist?(master_key_path) ? File.read(master_key_path).strip : nil
    is_maintainer_md5 = maintainer_credentials_file?(credentials_path)

    if valid_hex_key?(local_key) && !is_maintainer_md5 && can_decrypt_credentials?(local_key, credentials_path)
      msg = "🔑 [Credentials] Local master.key and credentials.yml.enc are valid and cryptographically paired."
      block_given? ? yield(msg) : (puts msg unless quiet)
      push_gcp_secret_key(local_key) if sync_gcp
      return { status: :ok, key: local_key, action: :none }
    end

    # Determine which key to use:
    # 1. Valid local key (if user already created master.key)
    # 2. Valid key in GCP Secret Manager (e.g., Computer 2 scenario)
    # 3. Freshly generated 32-char hex key
    target_key = if valid_hex_key?(local_key)
                   local_key
                 elsif sync_gcp && (gcp_key = fetch_gcp_secret_key)
                   msg = "📥 [Credentials] Pulled valid rails-master-key from GCP Secret Manager."
                   block_given? ? yield(msg) : (puts msg unless quiet)
                   gcp_key
                 else
                   SecureRandom.hex(16)
                 end

    # Fix C1 ("Computer 2" scenario): If credentials.yml.enc is ALREADY a custom encrypted file
    # (NOT the shipped SAMPLE_APP_CREDENTIALS) and `target_key` can already decrypt it,
    # ONLY restore the missing local `master.key` — NEVER overwrite `credentials.yml.enc`!
    if !is_maintainer_md5 && can_decrypt_credentials?(target_key, credentials_path)
      msg = "✅ [Credentials] Restored local blog/config/master.key matching existing credentials.yml.enc (preserved without rewriting)."
      block_given? ? yield(msg) : (puts msg unless quiet)
      FileUtils.mkdir_p(File.dirname(master_key_path))
      File.write(master_key_path, "#{target_key}\n")
      File.chmod(0o600, master_key_path) rescue nil
      push_gcp_secret_key(target_key) if sync_gcp
      return { status: :restored_key_only, key: target_key, action: :restored_key_only }
    end

    if is_maintainer_md5 && !quiet
      msg = "🔄 [Credentials] Detected SAMPLE_APP_CREDENTIALS (MD5: #{SAMPLE_APP_CREDENTIALS}). Re-encrypting with your workshop master.key..."
      block_given? ? yield(msg) : puts(msg)
    elsif !quiet
      msg = "🔐 [Credentials] Generating paired blog/config/master.key and blog/config/credentials.yml.enc..."
      block_given? ? yield(msg) : puts(msg)
    end

    FileUtils.mkdir_p(File.dirname(master_key_path))
    File.write(master_key_path, "#{target_key}\n")
    File.chmod(0o600, master_key_path) rescue nil
    write_encrypted_credentials!(target_key, credentials_path)

    if sync_gcp
      if push_gcp_secret_key(target_key)
        msg = "☁️  [Credentials] Synced master.key to GCP Secret Manager (rails-master-key)."
        block_given? ? yield(msg) : (puts msg unless quiet)
      end
    end

    { status: :regenerated, key: target_key, action: :reencrypted }
  end
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.include?("--check")
    res = WorkshopCredentialsManager.check
    exit(res[:status] == :ok ? 0 : 1)
  else
    sync_gcp = ARGV.include?("--sync-gcp")
    quiet = ARGV.include?("--quiet")
    res = WorkshopCredentialsManager.ensure!(sync_gcp: sync_gcp, quiet: quiet)
    exit([:ok, :regenerated, :restored_key_only].include?(res[:status]) ? 0 : 1)
  end
end
