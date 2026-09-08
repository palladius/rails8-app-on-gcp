require "minitest/autorun"
require "open3"
require "fileutils"
require "tmpdir"

class WorkshopDiagnosticsTest < Minitest::Test
  SCRIPT_PATH = File.expand_path("../bin/workshop_diagnostics.rb", __dir__)

  def test_fails_when_gcp_email_and_gcloud_account_missing
    Dir.mktmpdir do |dir|
      # In an empty tempdir with empty fake gcloud returning nothing
      env = { "CLOUDSDK_CORE_ACCOUNT" => "", "GCP_EMAIL" => "", "ADMIN_EMAIL" => "" }
      stdout, _stderr, status = Open3.capture3(env, "ruby", SCRIPT_PATH, chdir: dir)
      # Must report GCP_EMAIL missing if gcloud has no active account
      # (or if gcloud is mocked/absent in isolated env)
      assert_includes stdout, "GCP_EMAIL"
    end
  end

  def test_warns_when_gcp_email_is_not_google_or_gmail
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, ".env"), "GCP_EMAIL=student@yahoo.com\nGCP_PROJECT_ID=dummy\n")
      stdout, _stderr, _status = Open3.capture3("ruby", SCRIPT_PATH, chdir: dir)
      assert_includes stdout, "GCP_EMAIL (student@yahoo.com) is not a @gmail.com or @google.com address"
      assert_includes stdout, "Billable resources"
      assert_includes stdout, "terraform apply"
    end
  end

  def test_warns_when_admin_email_differs_from_gcp_email
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, ".env"), "GCP_EMAIL=ricc@google.com\nADMIN_EMAIL=custom@gmail.com\nGCP_PROJECT_ID=dummy\n")
      stdout, _stderr, _status = Open3.capture3("ruby", SCRIPT_PATH, chdir: dir)
      assert_includes stdout, "ADMIN_EMAIL (custom@gmail.com) and GCP_EMAIL (ricc@google.com) differ!"
    end
  end
end
