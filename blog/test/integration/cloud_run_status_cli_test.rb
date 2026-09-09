require "test_helper"

class CloudRunStatusCliTest < ActiveSupport::TestCase
  CLI_PATH = Rails.root.join("../bin/cloud_run_status.sh").to_s

  test "bin/cloud_run_status.sh exists and is executable" do
    assert File.exist?(CLI_PATH), "bin/cloud_run_status.sh should exist"
    assert File.executable?(CLI_PATH), "bin/cloud_run_status.sh should be executable"
  end

  test "bin/cloud_run_status.sh --url-only outputs provided URL" do
    out = `#{CLI_PATH} https://example-service-12345.europe-west1.run.app --url-only 2>&1`.strip
    assert_equal "https://example-service-12345.europe-west1.run.app", out
  end
end
