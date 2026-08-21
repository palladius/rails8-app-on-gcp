require "test_helper"

class CloudStorageConfigurationTest < ActiveSupport::TestCase
  test "production environment is configured for google_prod storage" do
    production_config = File.read(Rails.root.join("config/environments/production.rb"))
    assert_match(/config\.active_storage\.service\s*=\s*:google_prod/, production_config)
    assert_match(/config\.active_storage\.resolve_model_to_route\s*=\s*:rails_storage_proxy/, production_config)
  end

  test "storage.yml contains google_prod configuration" do
    storage_yml = File.read(Rails.root.join("config/storage.yml"))
    assert_match(/google_prod:/, storage_yml)
    assert_match(/iam: true/, storage_yml)
  end
end
