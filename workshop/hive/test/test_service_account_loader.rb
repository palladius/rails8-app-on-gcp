# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/service_account_loader"

class ServiceAccountLoaderTest < Minitest::Test
  def setup
    @original_env = ENV.to_h
    ENV.delete("HIVE_SERVICE_ACCOUNT_KEY_B64")
    ENV.delete("HIVE_SERVICE_ACCOUNT_JSON")
    ENV.delete("GOOGLE_APPLICATION_CREDENTIALS")
  end

  def teardown
    ENV.clear
    @original_env.each { |k, v| ENV[k] = v }
  end

  def test_loads_from_raw_json_env
    valid_json = '{"type": "service_account", "project_id": "test-proj", "client_email": "sa@test-proj.iam.gserviceaccount.com"}'
    ENV["HIVE_SERVICE_ACCOUNT_JSON"] = valid_json

    creds_hash = WorkshopHive::ServiceAccountLoader.load_credentials_hash
    refute_nil creds_hash
    assert_equal "test-proj", creds_hash["project_id"]
    assert_equal "sa@test-proj.iam.gserviceaccount.com", creds_hash["client_email"]
  end

  def test_loads_from_base64_env
    valid_json = '{"type": "service_account", "project_id": "b64-proj"}'
    ENV["HIVE_SERVICE_ACCOUNT_KEY_B64"] = Base64.strict_encode64(valid_json)

    creds_hash = WorkshopHive::ServiceAccountLoader.load_credentials_hash
    refute_nil creds_hash
    assert_equal "b64-proj", creds_hash["project_id"]
  end

  def test_returns_nil_when_no_credentials_configured
    assert_nil WorkshopHive::ServiceAccountLoader.load_credentials_hash
  end
end
