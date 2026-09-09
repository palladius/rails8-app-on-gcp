require "minitest/autorun"
require "open3"
require "fileutils"
require "tmpdir"

class WorkshopDiagnosticsTest < Minitest::Test
  SCRIPT_PATH = File.expand_path("../bin/workshop_diagnostics.rb", __dir__)

  def test_fails_when_gcp_account_and_gcloud_account_missing
    Dir.mktmpdir do |dir|
      env = { "CLOUDSDK_CORE_ACCOUNT" => "", "GOOGLE_CLOUD_ACCOUNT" => "", "GCP_EMAIL" => "", "ADMIN_EMAIL" => "" }
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
end
