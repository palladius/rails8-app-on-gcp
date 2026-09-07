require "test_helper"
require "yaml"

class DockerComposeConfigurationTest < ActiveSupport::TestCase
  test "compose.yaml exists and contains required services for local dev" do
    compose_path = Rails.root.join("compose.yaml")
    assert File.exist?(compose_path), "compose.yaml should exist"

    config = YAML.load_file(compose_path)
    services = config["services"]

    assert_not_nil services["web"], "web service should be present"
    assert_not_nil services["worker"], "worker service should be present"
    assert_not_nil services["db"], "db service should be present"
    assert_not_nil services["mailpit"], "mailpit service should be present"
    assert_not_nil services["db-admin"], "db-admin service should be present"
    assert_not_nil services["gcs"], "gcs service should be present"
  end

  test "compose.prod.yaml contains multi-container Cloud Run services" do
    compose_prod_path = Rails.root.join("compose.prod.yaml")
    assert File.exist?(compose_prod_path), "compose.prod.yaml should exist"

    config = YAML.load_file(compose_prod_path)
    services = config["services"]

    assert_not_nil services["web"], "web service should be present"
    assert_not_nil services["worker"], "worker service should be present"
    assert_not_nil services["cloudsql-proxy"], "cloudsql-proxy service should be present"

    # Cloud SQL Proxy assertions
    assert_match(/cloud-sql-proxy/, services["cloudsql-proxy"]["image"])
    assert_includes services["cloudsql-proxy"]["command"], "--address=0.0.0.0"
    assert_includes services["cloudsql-proxy"]["command"], "--port=5432"
  end

  test "database.yml production queue uses DATABASE_URL or DATABASE_QUEUE_URL when set" do
    db_yml_path = Rails.root.join("config/database.yml")
    template = ERB.new(File.read(db_yml_path))

    # Test without DATABASE_URL (SQLite fallback)
    config_sqlite = YAML.safe_load(template.result_with_hash({}), aliases: true)
    assert_equal "sqlite3", config_sqlite.dig("production", "queue", "adapter")

    # Test with DATABASE_URL set
    ENV["DATABASE_URL"] = "postgresql://rails_user:secret@cloudsql-proxy:5432/rails_production"
    begin
      template_pg = ERB.new(File.read(db_yml_path))
      config_pg = YAML.safe_load(template_pg.result_with_hash({}), aliases: true)
      assert_equal "postgresql", config_pg.dig("production", "queue", "adapter")
      assert_equal ENV["DATABASE_URL"], config_pg.dig("production", "queue", "url")
    ensure
      ENV.delete("DATABASE_URL")
    end
  end
end
