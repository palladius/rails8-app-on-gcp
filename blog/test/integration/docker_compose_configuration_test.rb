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
  # Cloud Run mounts DB_PASSWORD from Secret Manager, so production must be able to build its
  # PostgreSQL connection from discrete settings instead of a URL that embeds the password.
  test "database.yml production uses discrete DB_* settings when DB_HOST and DB_PASSWORD are set" do
    config = render_database_yml("DB_HOST" => "cloudsql-proxy", "DB_PASSWORD" => "p@ss:w/rd#1")
    %w[primary cache queue cable].each do |name|
      db = config.dig("production", name)
      assert_equal "postgresql", db["adapter"], "production.#{name} adapter"
      assert_equal "cloudsql-proxy", db["host"], "production.#{name} host"
      assert_equal 5432, db["port"], "production.#{name} port"
      assert_equal "rails_production", db["database"], "production.#{name} database"
      assert_equal "rails_user", db["username"], "production.#{name} username"
      assert_equal "p@ss:w/rd#1", db["password"], "production.#{name} password must survive special characters"
      assert_nil db["url"], "production.#{name} must not build a URL around the password"
    end
    assert_equal "db/queue_migrate", config.dig("production", "queue", "migrations_paths")
  end

  test "database.yml production stays on SQLite while DB_PASSWORD is not mounted yet" do
    config = render_database_yml("DB_HOST" => "cloudsql-proxy", "DB_PASSWORD" => nil)
    assert_equal "sqlite3", config.dig("production", "primary", "adapter")
    assert_equal "sqlite3", config.dig("production", "queue", "adapter")
  end

  test "database.yml production prefers DATABASE_URL over discrete DB_* settings" do
    url = "postgresql://rails_user:secret@cloudsql-proxy:5432/rails_production"
    config = render_database_yml("DATABASE_URL" => url, "DB_HOST" => "other-host", "DB_PASSWORD" => "other")
    assert_equal url, config.dig("production", "primary", "url")
    assert_nil config.dig("production", "primary", "host")
  end

  private

  DB_ENV_KEYS = %w[DATABASE_URL DATABASE_CACHE_URL DATABASE_QUEUE_URL DATABASE_CABLE_URL
                   DB_HOST DB_PORT DB_NAME DB_USER DB_PASSWORD].freeze

  def render_database_yml(overrides)
    saved = DB_ENV_KEYS.to_h { |k| [ k, ENV[k] ] }
    DB_ENV_KEYS.each { |k| ENV.delete(k) }
    overrides.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
    YAML.safe_load(ERB.new(File.read(Rails.root.join("config/database.yml"))).result, aliases: true)
  ensure
    saved.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end
end
