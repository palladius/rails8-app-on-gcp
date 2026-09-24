# frozen_string_literal: true

require "minitest/autorun"
require "yaml"
require "tmpdir"
require_relative "../bin/ensure_workshop_credentials"

class IacCodelabContractsTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)
  SECRETS_TF_PATH = File.join(REPO_ROOT, "iac", "secrets.tf")
  CLOUDRUN_TF_PATH = File.join(REPO_ROOT, "iac", "cloudrun.tf")
  TERRAFORM_APPLY_SH_PATH = File.join(REPO_ROOT, "iac", "bin", "terraform-apply.sh")
  SKELETON_YAML_PATH = File.join(REPO_ROOT, "workshop", "skeleton.yaml")

  def setup
    @secrets_tf = File.read(SECRETS_TF_PATH)
    @cloudrun_tf = File.read(CLOUDRUN_TF_PATH)
    @tf_apply_sh = File.read(TERRAFORM_APPLY_SH_PATH)
    @skeleton = YAML.load_file(SKELETON_YAML_PATH)
  end

  # Finding #9 (FL_E001) & Decision #1:
  # Step 5.4 runs `gcloud secrets get-iam-policy rails-master-key --filter="bindings.members:$RUN_SA"`
  # Terraform MUST attach a secret-level IAM binding (`google_secret_manager_secret_iam_member`)
  # on `rails-master-key` for `rails-cloudrun-sa` (and Default Compute SA for compose up compatibility).
  def test_terraform_grants_secret_level_iam_binding_on_rails_master_key
    combined_tf = "#{@secrets_tf}\n#{@cloudrun_tf}"
    assert_match(/resource\s+"google_secret_manager_secret_iam_member"/, combined_tf,
                 "Terraform must define 'google_secret_manager_secret_iam_member' on rails-master-key so 'gcloud secrets get-iam-policy rails-master-key' is non-empty in Step 5.4")
    assert_match(/roles\/secretmanager\.secretAccessor/, combined_tf)
  end

  # Decision #1: Because `gcloud run compose up` (Step 6) uses a hardcoded Go template without serviceAccountName,
  # Terraform must also grant runtime roles to the Default Compute SA so the 3-container compose up probe succeeds.
  def test_terraform_grants_runtime_roles_to_both_rails_cloudrun_sa_and_compute_sa
    combined_tf = "#{@secrets_tf}\n#{@cloudrun_tf}"
    assert_match(/rails-cloudrun-sa/, combined_tf)
    assert_match(/-compute@developer\.gserviceaccount\.com/, combined_tf,
                 "Terraform must also grant runtime roles to Default Compute SA so 'gcloud run compose up' startup probes succeed")
  end

  # Finding #10 (FL_E001) & Decision #2:
  # 1. `iac/secrets.tf` must NOT fall back to the forbidden dummy string "0123456789abcdef0123456789abcdef".
  # 2. `iac/bin/terraform-apply.sh` must invoke `ensure_workshop_credentials.rb` BEFORE `terraform apply`.
  def test_secrets_tf_never_uses_static_dummy_key_and_terraform_apply_ensures_credentials
    refute_match(/0123456789abcdef0123456789abcdef/, @secrets_tf,
                 "iac/secrets.tf must NOT contain the static dummy key '0123456789abcdef0123456789abcdef' (use random_id fallback instead)")
    assert_match(/ensure_workshop_credentials\.rb/, @tf_apply_sh,
                 "iac/bin/terraform-apply.sh must run bin/ensure_workshop_credentials.rb before terraform apply")
  end

  # Decision #2: Test WorkshopCredentialsManager detects SAMPLE_APP_CREDENTIALS and generates a valid pair
  def test_workshop_credentials_manager_detects_maintainer_md5_and_reencrypts
    assert_equal "7b856d06f492f293bea59a5323150d8c", WorkshopCredentialsManager::SAMPLE_APP_CREDENTIALS
    assert_equal "7b856d06f492f293bea59a5323150d8c", WorkshopCredentialsManager::SAMPLE_APP_CREDENTIALS_MD5
    refute WorkshopCredentialsManager.valid_hex_key?("0123456789abcdef0123456789abcdef"),
           "Dummy key must be rejected by valid_hex_key?"

    Dir.mktmpdir do |dir|
      cred_file = File.join(dir, "credentials.yml.enc")
      fresh_key = "a1b2c3d4e5f60718293a4b5c6d7e8f90"
      assert WorkshopCredentialsManager.valid_hex_key?(fresh_key)

      WorkshopCredentialsManager.write_encrypted_credentials!(fresh_key, cred_file)
      assert File.exist?(cred_file)
      new_md5 = Digest::MD5.file(cred_file).hexdigest
      refute_equal WorkshopCredentialsManager::SAMPLE_APP_CREDENTIALS, new_md5,
                   "Newly encrypted credentials.yml.enc MUST have a different MD5 from SAMPLE_APP_CREDENTIALS!"
      assert WorkshopCredentialsManager.can_decrypt_credentials?(fresh_key, cred_file),
             "Generated credentials.yml.enc must be decryptable by the key that encrypted it"
      refute WorkshopCredentialsManager.can_decrypt_credentials?("ffffffffffffffffffffffffffffffff", cred_file),
             "Different key must fail to decrypt credentials.yml.enc"
    end
  end

  def test_ensure_end_to_end_reencrypts_and_changes_md5_when_starting_from_original_devs_file
    require "tmpdir"
    require "digest"
    require_relative "../bin/ensure_workshop_credentials"

    Dir.mktmpdir do |fake_repo|
      config_dir = File.join(fake_repo, "blog", "config")
      FileUtils.mkdir_p(config_dir)
      # Copy the original repo credentials.yml.enc into the temp repo without a master.key
      real_creds = File.join(REPO_ROOT, "blog", "config", "credentials.yml.enc")
      temp_creds = File.join(config_dir, "credentials.yml.enc")
      FileUtils.cp(real_creds, temp_creds)

      result = WorkshopCredentialsManager.ensure!(repo_root: fake_repo, sync_gcp: false)
      assert_equal :regenerated, result[:status]
      new_md5 = Digest::MD5.file(temp_creds).hexdigest
      refute_equal WorkshopCredentialsManager::SAMPLE_APP_CREDENTIALS, new_md5,
                   "Re-encrypted credentials.yml.enc MD5 (#{new_md5}) MUST differ from SAMPLE_APP_CREDENTIALS!"
      assert WorkshopCredentialsManager.can_decrypt_credentials?(result[:key], temp_creds),
             "New master.key must decrypt the newly encoded credentials.yml.enc!"
    end
  end

  # Finding #10b (FL_E001): skeleton.yaml Ruby runner evaluations must pin RBENV_VERSION=3.4.5
  def test_skeleton_yaml_rails_runner_evals_pin_rbenv_version_3_4_5
    [5, 6].each do |step_num|
      step = @skeleton["steps"].find { |s| s["number"] == step_num }
      eval_item = (step["evals"] || []).find { |e| e["id"] == "step-#{step_num}-ruby-status-json-step" }
      refute_nil eval_item, "Missing step-#{step_num}-ruby-status-json-step in skeleton.yaml"
      assert_match(/"RBENV_VERSION"\s*=>\s*"3\.4\.5"/, eval_item["code"],
                   "step-#{step_num}-ruby-status-json-step must set RBENV_VERSION => 3.4.5 in env hash")
    end
  end
end
