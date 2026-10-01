require "minitest/autorun"
require "open3"
require "fileutils"
require "tmpdir"

class WorkshopDiagnosticsTest < Minitest::Test
  SCRIPT_PATH = File.expand_path("../bin/workshop_diagnostics.rb", __dir__)

  def test_fails_when_gcp_account_and_gcloud_account_missing
    Dir.mktmpdir do |dir|
      env = { "CLOUDSDK_CORE_ACCOUNT" => "", "GOOGLE_CLOUD_ACCOUNT" => "", "ADMIN_EMAIL" => "" }
      stdout, _stderr, status = Open3.capture3(env, "ruby", SCRIPT_PATH, chdir: dir)
      assert_includes stdout, "GOOGLE_CLOUD_ACCOUNT"
    end
  end

  def test_warns_when_google_cloud_account_is_not_google_or_gmail
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, ".env"), "GOOGLE_CLOUD_ACCOUNT=student@yahoo.com\nGOOGLE_CLOUD_PROJECT=dummy\n")
      stdout, _stderr, _status = Open3.capture3("ruby", SCRIPT_PATH, chdir: dir)
      assert_includes stdout, "GOOGLE_CLOUD_ACCOUNT (student@yahoo.com) is not a @gmail.com or @google.com address"
      assert_includes stdout, "Billable resources"
      assert_includes stdout, "terraform apply"
    end
  end

  def test_warns_when_admin_email_differs_from_google_cloud_account
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, ".env"), "GOOGLE_CLOUD_ACCOUNT=ricc@google.com\nADMIN_EMAIL=custom@gmail.com\nGOOGLE_CLOUD_PROJECT=dummy\n")
      stdout, _stderr, _status = Open3.capture3("ruby", SCRIPT_PATH, chdir: dir)
      assert_includes stdout, "ADMIN_EMAIL (custom@gmail.com) and GOOGLE_CLOUD_ACCOUNT (ricc@google.com) differ!"
    end
  end

  def test_fails_when_deprecated_project_id_found_in_env
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, ".env"), "GOOGLE_CLOUD_ACCOUNT=ricc@google.com\nPROJECT_ID=dummy-legacy-project\n")
      stdout, _stderr, status = Open3.capture3("ruby", SCRIPT_PATH, chdir: dir)
      assert_equal 1, status.exitstatus
      assert_includes stdout, "Found deprecated variable 'PROJECT_ID'"
      assert_includes stdout, "GOOGLE_CLOUD_PROJECT"
    end
  end

  def test_fails_when_deprecated_gcloud_user_found_in_env
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, ".env"), "GOOGLE_CLOUD_ACCOUNT=ricc@google.com\nGCLOUD_USER=ricc@google.com\nGOOGLE_CLOUD_PROJECT=dummy\n")
      stdout, _stderr, status = Open3.capture3("ruby", SCRIPT_PATH, chdir: dir)
      assert_equal 1, status.exitstatus
      assert_includes stdout, "Found deprecated variable 'GCLOUD_USER'"
      assert_includes stdout, "GOOGLE_CLOUD_ACCOUNT"
    end
  end

  def test_fails_when_banned_gcp_project_id_found_in_env
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, ".env"), "GOOGLE_CLOUD_ACCOUNT=ricc@google.com\nGCP_PROJECT_ID=dummy\n")
      stdout, _stderr, status = Open3.capture3("ruby", SCRIPT_PATH, chdir: dir)
      assert_equal 1, status.exitstatus
      assert_includes stdout, "Found deprecated variable 'GCP_PROJECT_ID'"
      assert_includes stdout, "GOOGLE_CLOUD_PROJECT"
    end
  end

  def test_fails_when_banned_gcp_region_found_in_env
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, ".env"), "GOOGLE_CLOUD_ACCOUNT=ricc@google.com\nGOOGLE_CLOUD_PROJECT=dummy\nGCP_REGION=us-central1\n")
      stdout, _stderr, status = Open3.capture3("ruby", SCRIPT_PATH, chdir: dir)
      assert_equal 1, status.exitstatus
      assert_includes stdout, "Found deprecated variable 'GCP_REGION'"
      assert_includes stdout, "GOOGLE_CLOUD_REGION"
    end
  end

  def test_fails_when_banned_gcp_email_found_in_env
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, ".env"), "GCP_EMAIL=ricc@google.com\nGOOGLE_CLOUD_PROJECT=dummy\n")
      stdout, _stderr, status = Open3.capture3("ruby", SCRIPT_PATH, chdir: dir)
      assert_equal 1, status.exitstatus
      assert_includes stdout, "Found deprecated variable 'GCP_EMAIL'"
      assert_includes stdout, "GOOGLE_CLOUD_ACCOUNT"
    end
  end

  # --- Default Compute SA check vs. Terraform ordering (#163) ---
  # Step 1 runs `just workshop-test` BEFORE `just terraform-apply`, and Terraform
  # (iac/cicd.tf) is what grants the Default Compute SA its build roles. A fresh
  # project is therefore expected to have none yet.

  def run_diagnostics_with_fake_gcloud(terraform_applied:)
    Dir.mktmpdir do |dir|
      bin_dir = File.join(dir, "fakebin")
      FileUtils.mkdir_p(bin_dir)
      fake = File.join(bin_dir, "gcloud")
      File.write(fake, <<~SH)
        #!/bin/sh
        case "$*" in
          "auth list --filter=status:ACTIVE"*) echo student@gmail.com ;;
          "auth list"*) echo student@gmail.com ;;
          "beta billing projects describe"*) echo True ;;
          "auth application-default print-access-token"*) echo token ;;
          "projects describe"*) echo 123456789 ;;
          "projects get-iam-policy"*) ;;  # no roles at all
          "storage buckets describe"*) exit #{terraform_applied ? 0 : 1} ;;
          "storage ls"*) exit 1 ;;
          *) ;;
        esac
      SH
      File.chmod(0o755, fake)
      File.write(File.join(dir, ".env"), "GOOGLE_CLOUD_ACCOUNT=student@gmail.com\nGOOGLE_CLOUD_PROJECT=fresh-project\n")
      env = { "PATH" => "#{bin_dir}:#{ENV['PATH']}" }
      Open3.capture3(env, "ruby", SCRIPT_PATH, chdir: dir)
    end
  end

  def test_compute_sa_without_roles_is_informational_before_terraform_apply
    stdout, _stderr, _status = run_diagnostics_with_fake_gcloud(terraform_applied: false)
    assert_includes stdout, "Checking Default Compute SA"
    refute_includes stdout, "INSUFFICIENT"
    refute_includes stdout, "just project-status"
    assert_includes stdout, "just terraform-apply"
  end

  def test_compute_sa_without_roles_still_warns_after_terraform_apply
    stdout, _stderr, _status = run_diagnostics_with_fake_gcloud(terraform_applied: true)
    assert_includes stdout, "INSUFFICIENT"
    assert_includes stdout, "lacks the roles Cloud Build needs"
  end
end
