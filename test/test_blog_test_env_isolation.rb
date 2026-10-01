# frozen_string_literal: true

require "minitest/autorun"
require "open3"

# Issue #170: blog/config/environments/test.rb read the ambient ACTIVE_STORAGE_SERVICE.
# The codelab exports ACTIVE_STORAGE_SERVICE=google (an alias of the PRODUCTION bucket)
# in Step 6, so `just workshop-eval 6` ran the Rails test suite against the real prod
# bucket and left orphaned fixture blobs next to the attendee's uploads.
class BlogTestEnvIsolationTest < Minitest::Test
  BLOG_DIR = File.expand_path("../blog", __dir__)
  PROBE = "puts Rails.application.config.active_storage.service"

  def probe(env)
    clean = { "ACTIVE_STORAGE_SERVICE" => nil, "TEST_ACTIVE_STORAGE_SERVICE" => nil }
    Open3.capture3(clean.merge(env), "bin/rails", "runner", "-e", "test", PROBE, chdir: BLOG_DIR)
  end

  def test_test_env_defaults_to_the_disk_test_service
    stdout, stderr, status = probe({})
    assert status.success?, stderr
    assert_equal "test", stdout.lines.last.to_s.strip
  end

  def test_test_env_ignores_ambient_active_storage_service_from_the_codelab
    stdout, stderr, status = probe("ACTIVE_STORAGE_SERVICE" => "google")
    assert status.success?, stderr
    assert_equal "test", stdout.lines.last.to_s.strip,
                 "the test env must not follow ACTIVE_STORAGE_SERVICE (google = production bucket)"
  end

  def test_test_env_can_opt_in_to_the_dedicated_test_bucket
    stdout, stderr, status = probe("TEST_ACTIVE_STORAGE_SERVICE" => "google_test")
    assert status.success?, stderr
    assert_equal "google_test", stdout.lines.last.to_s.strip
  end

  def test_test_env_refuses_to_boot_against_the_production_bucket
    %w[google google_prod].each do |service|
      _stdout, stderr, status = probe("TEST_ACTIVE_STORAGE_SERVICE" => service)
      refute status.success?, "test env must refuse #{service}"
      assert_match(/production bucket/i, stderr)
    end
  end
end
