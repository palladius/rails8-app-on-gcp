require "minitest/autorun"
require "open3"
require "fileutils"
require "tmpdir"

class WorkshopDiagnosticsTest < Minitest::Test
  SCRIPT_PATH = File.expand_path("../bin/workshop_diagnostics.rb", __dir__)

  def test_fails_when_env_missing_admin_email
    Dir.mktmpdir do |dir|
      stdout, _stderr, status = Open3.capture3("ruby", SCRIPT_PATH, chdir: dir)
      assert_equal 1, status.exitstatus
      assert_includes stdout, "ADMIN_EMAIL is missing"
    end
  end

  def test_warns_when_admin_email_is_not_gmail
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, ".env"), "ADMIN_EMAIL=custom@yahoo.com\nGCP_PROJECT_ID=dummy\n")
      stdout, _stderr, _status = Open3.capture3("ruby", SCRIPT_PATH, chdir: dir)
      assert_includes stdout, "ADMIN_EMAIL is not a @gmail.com or @google.com address"
    end
  end
end
