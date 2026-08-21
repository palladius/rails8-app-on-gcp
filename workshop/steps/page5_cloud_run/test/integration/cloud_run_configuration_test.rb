require "test_helper"
require "yaml"

class CloudRunConfigurationTest < ActiveSupport::TestCase
  test "compose.prod.yaml contains expected services" do
    compose_path = Rails.root.join("compose.prod.yaml")
    assert File.exist?(compose_path), "compose.prod.yaml should exist"
    
    compose_config = YAML.load_file(compose_path)
    services = compose_config["services"]
    
    assert_not_nil services, "services block should be present"
    assert_not_nil services["web"], "web service should be present"
    assert_not_nil services["worker"], "worker service should be present"
    assert_not_nil services["cloudsql-proxy"], "cloudsql-proxy service should be present"
    
    # Check cloudsql-proxy command structure (basic check)
    assert_match(/cloud-sql-proxy/, services["cloudsql-proxy"]["command"].join(" "))
  end
end
