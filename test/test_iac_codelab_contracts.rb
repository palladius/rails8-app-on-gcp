# frozen_string_literal: true

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require "minitest/autorun"
require "yaml"
require "open3"
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

  # Review Fix C1 ("Computer 2" scenario):
  # When a custom credentials.yml.enc is already present in git (MD5 != SAMPLE_APP_CREDENTIALS)
  # and master.key is missing locally, pulling the matching key from GCP must ONLY restore master.key
  # and MUST NOT overwrite credentials.yml.enc!
  def test_c1_computer_2_restores_key_without_overwriting_custom_credentials_yml_enc
    Dir.mktmpdir do |fake_repo|
      config_dir = File.join(fake_repo, "blog", "config")
      FileUtils.mkdir_p(config_dir)
      temp_creds = File.join(config_dir, "credentials.yml.enc")
      temp_master = File.join(config_dir, "master.key")
      computer_1_key = "11223344556677889900aabbccddeeff"

      WorkshopCredentialsManager.write_encrypted_credentials!(computer_1_key, temp_creds)
      custom_md5_before = Digest::MD5.file(temp_creds).hexdigest
      refute_equal WorkshopCredentialsManager::SAMPLE_APP_CREDENTIALS, custom_md5_before

      # Stub fetch_gcp_secret_key and push_gcp_secret_key for Computer 2
      WorkshopCredentialsManager.singleton_class.class_eval do
        alias_method :orig_fetch_gcp, :fetch_gcp_secret_key
        alias_method :orig_push_gcp, :push_gcp_secret_key
        define_method(:fetch_gcp_secret_key) { |*_args| computer_1_key }
        define_method(:push_gcp_secret_key) { |*_args| true }
      end

      begin
        result = WorkshopCredentialsManager.ensure!(repo_root: fake_repo, sync_gcp: true, quiet: true)
        assert_equal :restored_key_only, result[:status], "Computer 2 must return :restored_key_only"
        assert_equal custom_md5_before, Digest::MD5.file(temp_creds).hexdigest,
                     "Computer 2 MUST NOT overwrite existing custom credentials.yml.enc!"
        assert_equal computer_1_key, File.read(temp_master).strip
      ensure
        WorkshopCredentialsManager.singleton_class.class_eval do
          alias_method :fetch_gcp_secret_key, :orig_fetch_gcp
          alias_method :push_gcp_secret_key, :orig_push_gcp
        end
      end
    end
  end

  # Review Fix C2, C3, M4:
  # - No project-wide roles/secretmanager.secretAccessor or roles/storage.objectAdmin in cloudrun.tf
  # - Bucket-scoped google_storage_bucket_iam_member in cloudrun.tf
  # - Lifecycle precondition on rails_master_key in secrets.tf
  def test_c2_c3_m4_least_privilege_iam_and_terraform_precondition
    refute_match(/roles\/secretmanager\.secretAccessor/, @cloudrun_tf,
                 "iac/cloudrun.tf must NOT grant project-wide roles/secretmanager.secretAccessor (scoped per-secret in secrets.tf)")
    assert_match(/resource\s+"google_storage_bucket_iam_member"/, @cloudrun_tf,
                 "iac/cloudrun.tf must scope roles/storage.objectAdmin per-bucket via google_storage_bucket_iam_member")
    assert_match(/precondition\s*\{/, @secrets_tf,
                 "iac/secrets.tf must enforce a lifecycle precondition verifying blog/config/master.key exists")
  end

  # Issue #164: Google creates the Default Compute SA lazily, a few seconds after the
  # first APIs are enabled. Any Terraform resource that names it must wait for it, or
  # the first `terraform apply` on a fresh project fails with "Service account ... does not exist".
  def test_every_resource_using_default_compute_sa_waits_for_it_to_exist
    iac_dir = File.join(REPO_ROOT, "iac")
    wait = "terraform_data.wait_for_default_compute_sa"
    uses_sa = ->(body) { body.include?("-compute@developer.gserviceaccount.com") || body.include?("local.runtime_secret_accessors") }

    offenders = []
    Dir.glob(File.join(iac_dir, "*.tf")).each do |file|
      File.read(file).scan(/^resource\s+"([^"]+)"\s+"([^"]+)"\s*\{\n(.*?)^\}/m) do |type, name, body|
        next if type == "terraform_data" # the waiter itself
        next unless uses_sa.call(body)
        offenders << "#{File.basename(file)}: #{type}.#{name}" unless body.include?(wait)
      end
    end
    assert_empty offenders,
                 "These resources reference the Default Compute SA without depends_on #{wait} (#164):\n  #{offenders.join("\n  ")}"
  end

  WAIT_SCRIPT = File.join(REPO_ROOT, "iac", "bin", "wait-for-default-compute-sa.sh")

  def test_waiter_uses_the_script_and_does_not_force_the_compute_api
    wait_tf = File.read(File.join(REPO_ROOT, "iac", "default_compute_sa.tf"))
    assert_match(/resource\s+"terraform_data"\s+"wait_for_default_compute_sa"/, wait_tf)
    assert_match(/wait-for-default-compute-sa\.sh/, wait_tf)
    # The Default Compute SA appears without Compute Engine being enabled (#164 evidence), and enabling
    # it creates the permissive `default` VPC (open SSH/RDP firewall rules) on new projects.
    refute_match(/service\s*=\s*"compute\.googleapis\.com"/, wait_tf, "the waiter must not enable the Compute Engine API")
    iap_tf = File.read(File.join(REPO_ROOT, "iac", "iap.tf"))
    assert_match(/resource\s+"google_project_service"\s+"compute_api"\s*\{\s*count\s*=\s*var\.enable_iap/, iap_tf,
                 "compute.googleapis.com must stay opt-in via enable_iap")
  end

  # Runs iac/bin/wait-for-default-compute-sa.sh against a fake `gcloud`.
  def run_waiter(fake_gcloud_body, attempts: 5)
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "gcloud"), "#!/bin/sh\ncount_file=\"#{dir}/count\"\nn=$(cat \"$count_file\" 2>/dev/null || echo 0)\nn=$((n+1)); echo $n > \"$count_file\"\n#{fake_gcloud_body}\n")
      File.chmod(0o755, File.join(dir, "gcloud"))
      env = { "PATH" => "#{dir}:#{ENV['PATH']}", "WAIT_ATTEMPTS" => attempts.to_s, "WAIT_SLEEP" => "0" }
      out, err, status = Open3.capture3(env, WAIT_SCRIPT, "123-compute@developer.gserviceaccount.com", "proj")
      [out, err, status, File.read(File.join(dir, "count")).to_i]
    end
  end

  def test_waiter_retries_while_the_service_account_is_not_found_then_succeeds
    out, _err, status, calls = run_waiter('if [ "$n" -lt 3 ]; then echo "ERROR: (gcloud.iam.service-accounts.describe) NOT_FOUND: Unknown service account" >&2; exit 1; fi; echo ok')
    assert status.success?
    assert_equal 3, calls
    assert_match(/ready/i, out)
  end

  def test_waiter_fails_fast_with_the_real_error_when_it_is_not_a_not_found
    _out, err, status, calls = run_waiter('echo "ERROR: (gcloud.iam.service-accounts.describe) PERMISSION_DENIED: caller lacks iam.serviceAccounts.get" >&2; exit 1', attempts: 30)
    refute status.success?
    assert_equal 1, calls, "must not keep polling on an error that waiting cannot fix"
    assert_includes err, "PERMISSION_DENIED"
    assert_match(/gcloud auth list/, err)
  end

  def test_waiter_times_out_with_a_clear_message
    _out, err, status, calls = run_waiter('echo "ERROR: NOT_FOUND: Unknown service account" >&2; exit 1', attempts: 2)
    refute status.success?
    assert_equal 2, calls
    assert_match(/Timed out/, err)
  end
end

# FL008 (Friction Log 20260921-fl008, reworked from PR #155 on top of current main):
# contracts between workshop/CODELAB.md, workshop/skeleton.yaml, iac/*.tf and blog/bin/docker-entrypoint.
class Fl008StepFiveSixContractsTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)

  def setup
    @codelab = File.read(File.join(REPO_ROOT, "workshop", "CODELAB.md"))
    @skeleton_raw = File.read(File.join(REPO_ROOT, "workshop", "skeleton.yaml"))
    @skeleton = YAML.safe_load(@skeleton_raw)
    @iac_tf = Dir.glob(File.join(REPO_ROOT, "iac", "*.tf")).sort.map { |f| File.read(f) }.join("\n")
    @entrypoint = File.read(File.join(REPO_ROOT, "blog", "bin", "docker-entrypoint"))
    @skill = File.read(File.join(REPO_ROOT, "skills", "rails8app-workshop", "SKILL.md"))
  end

  # Shell commands in CODELAB.md with backslash line-continuations joined into one line.
  def codelab_commands
    @codelab.gsub(/\\\n/, " ").lines.map(&:strip)
  end

  def rails_migrate_commands
    codelab_commands.select { |l| l.match?(/\Agcloud run jobs \S+ rails-migrate\b/) }
  end

  # FL008-10: `terraform output -raw X` silently fell back (to "CHANGE_ME" for the DB password)
  # because iac/ never declared those outputs.
  def test_every_terraform_output_used_by_the_workshop_is_declared_in_iac
    used = (@codelab + @skeleton_raw).scan(/terraform output -raw ([a-z0-9_]+)/).flatten.uniq
    refute_empty used
    used.each do |name|
      assert_match(/^output\s+"#{name}"\s*\{/, @iac_tf,
                   "workshop runs `terraform output -raw #{name}` but iac/*.tf declares no output \"#{name}\"")
    end
  end

  def test_db_password_output_is_marked_sensitive
    block = @iac_tf[/^output\s+"db_password"\s*\{.*?^\}/m]
    refute_nil block, "iac/*.tf must declare output \"db_password\""
    assert_match(/sensitive\s*=\s*true/, block)
  end

  def test_codelab_never_falls_back_to_a_placeholder_db_password
    refute_match(/DB_PASSWORD=.*(CHANGE_ME|RailsWorkshopSecure)/, @codelab,
                 "A placeholder DB password makes Cloud Run fail later with PG::ConnectionBad")
  end

  # FL008-09: `--set-cloudsql-instances` prompts to enable sql-component.googleapis.com; with
  # `2>/dev/null` the (y/N) prompt was invisible and the terminal hung silently.
  def test_terraform_enables_the_sql_component_api
    assert_match(/service\s*=\s*"sql-component\.googleapis\.com"/, @iac_tf)
  end

  def test_rails_migrate_job_commands_do_not_hide_errors
    refute_empty rails_migrate_commands
    rails_migrate_commands.each do |cmd|
      refute_match(%r{2>/dev/null|\|\|\s*true}, cmd, "rails-migrate commands must not hide errors: #{cmd}")
    end
  end

  # FL008-12: the job must be safe to re-run. `db:schema:load:*` is `create_table force: :cascade`
  # (wipes pending Solid Queue jobs), so the job must go through the image ENTRYPOINT, whose
  # `ensure_solid_schemas` loads each schema only if its sentinel table is missing (#168).
  def test_rails_migrate_job_is_idempotent_and_goes_through_the_entrypoint
    deploy = rails_migrate_commands.find { |c| c.start_with?("gcloud run jobs deploy rails-migrate") }
    refute_nil deploy, "use `gcloud run jobs deploy rails-migrate` (create-or-update, safe to re-run)"
    rails_migrate_commands.each do |cmd|
      refute_match(/db:schema:load/, cmd, "db:schema:load is destructive on re-run: #{cmd}")
      refute_match(/--command[ =]["']?(?!["'])\S/, cmd, "do not override --command: it bypasses bin/docker-entrypoint")
    end
    assert_match(/--args[ =]"?\.\/bin\/rails,db:prepare,db:seed"?/, deploy)
    assert_includes deploy, "GOOGLE_CLOUD_ACCOUNT=", "db:seed needs GOOGLE_CLOUD_ACCOUNT for the admin user"
    assert_match(/--wait\b/, deploy)
  end

  def test_entrypoint_loads_solid_schemas_before_one_off_db_tasks
    branch = @entrypoint[/^elif .*db:prepare.*\n(?:\s*#.*\n)*\s*ensure_solid_schemas queue cache cable$/]
    refute_nil branch, "bin/docker-entrypoint must run `ensure_solid_schemas queue cache cable` for db:prepare / db:seed commands"
  end

  # FL008-02: on many Debian/Ubuntu setups `rbenv install` is missing until ruby-build is installed.
  def test_skill_installs_ruby_build_without_touching_the_global_ruby
    assert_match(/ruby-build/, @skill)
    refute_match(/rbenv global\s+\d/, @skill, "the repo's .ruby-version already selects 3.4.5; do not change the student's global Ruby")
  end

  # FL008-11: live readiness check for Deploy 4, skipped offline / in CI.
  def test_skeleton_step_6_has_a_live_cloud_run_readiness_eval_gated_on_workshop_live_eval
    step = @skeleton["steps"].find { |s| s["number"] == 6 }
    eval_item = step["evals"].find { |e| e["id"] == "step-6-shell-cloud-run-ready" }
    refute_nil eval_item
    assert_includes eval_item["command"], "WORKSHOP_LIVE_EVAL"
    assert_includes eval_item["command"], "gcloud run services describe blog"
  end
end
