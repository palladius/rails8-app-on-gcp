# frozen_string_literal: true

require "minitest/autorun"
require "yaml"
require "open3"

class DockerComposeContractsTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)
  COMPOSE_DEV_PATH = File.join(REPO_ROOT, "blog", "compose.yaml")
  ENTRYPOINT_PATH = File.join(REPO_ROOT, "blog", "bin", "docker-entrypoint")
  DATABASE_YML_PATH = File.join(REPO_ROOT, "blog", "config", "database.yml")
  SEEDS_RB_PATH = File.join(REPO_ROOT, "blog", "db", "seeds.rb")

  def setup
    @compose = YAML.load_file(COMPOSE_DEV_PATH)
    @entrypoint = File.read(ENTRYPOINT_PATH)
    @database_yml = File.read(DATABASE_YML_PATH)
    @seeds_rb = File.read(SEEDS_RB_PATH)
  end

  # Finding #5a (FL_E001): compose.yaml must pass ../.env via env_file to web and worker
  # so GOOGLE_CLOUD_ACCOUNT and APP_ADMIN_PASSWORD from repo root .env reach the containers.
  def test_compose_yaml_passes_root_env_file_to_web_and_worker
    %w[web worker].each do |service_name|
      svc = @compose.dig("services", service_name)
      refute_nil svc, "Service '#{service_name}' missing from blog/compose.yaml"
      env_files = Array(svc["env_file"]).map { |e| e.is_a?(Hash) ? e["path"] : e.to_s }
      assert(
        env_files.any? { |p| p.include?("../.env") },
        "blog/compose.yaml service '#{service_name}' must include '../.env' in env_file (got: #{env_files.inspect})"
      )
    end
  end

  # Finding #5b (FL_E001): blog/compose.yaml web command must NOT bypass bin/docker-entrypoint!
  def test_docker_entrypoint_recognizes_compose_web_command
    web_cmd = @compose.dig("services", "web", "command")
    refute_nil web_cmd, "services.web.command must be defined in blog/compose.yaml"

    # Extract how docker-entrypoint detects a rails server invocation
    assert_match(/rm -f .*server\.pid/, @entrypoint,
                 "blog/bin/docker-entrypoint should clean up stale tmp/pids/server.pid itself")

    # Verify that passing the web command to a dry-run check of the entrypoint condition triggers db:prepare
    refute_match(/^\s*command:\s*bash\s+-c\b/, File.read(COMPOSE_DEV_PATH),
                 "blog/compose.yaml must not wrap rails server in 'bash -c' if that bypasses docker-entrypoint")
  end

  # Finding #5c (FL_E001): worker container on fresh Postgres volume crashes with
  # PG::UndefinedTable: relation "solid_queue_processes" does not exist unless queue schema is loaded.
  def test_development_database_and_entrypoint_prepare_solid_queue_tables
    assert_match(/queue_schema\.rb|db:prepare:queue|db:schema:load:queue/, @entrypoint,
                 "blog/bin/docker-entrypoint must load queue schema (db/queue_schema.rb) so Solid Queue worker does not crash")
    assert_match(/queue:/, @database_yml,
                 "blog/config/database.yml must configure queue database migrations_paths")
    # Check that development section in database.yml also supports DATABASE_URL or queue migrations
    dev_section = @database_yml[/^development:.*?(?=^\w+:|\z)/m]
    refute_nil dev_section
    assert_match(/db\/queue_migrate/, dev_section,
                 "blog/config/database.yml 'development:' section must include 'db/queue_migrate' so db:prepare creates solid_queue_processes")
  end

  # Finding #5d (FL_E001): seeds.rb must update admin password when APP_ADMIN_PASSWORD changes,
  # even if the User record already existed in the database.
  def test_seeds_rb_updates_password_for_existing_admin_user
    assert_match(/admin_user\.update!.*password:\s*admin_password/m, @seeds_rb,
                 "blog/db/seeds.rb must update password on existing admin_user so changing APP_ADMIN_PASSWORD in .env takes effect on re-seed")
  end

  def test_compose_yaml_worker_runs_solid_queue_start_and_depends_on_db
    worker = @compose.dig("services", "worker")
    refute_nil worker, "compose.yaml must define a 'worker' service"
    assert_match(/solid_queue:start/, worker["command"].to_s,
                 "compose.yaml 'worker' service must run 'bin/rails solid_queue:start'")
    assert_includes worker["depends_on"].keys, "db",
                    "compose.yaml 'worker' service must depend on 'db' healthcheck"
  end

  def test_compose_yaml_includes_mailpit_and_adminer_services
    assert @compose.dig("services", "mailpit"), "compose.yaml must define 'mailpit' service on port 8025"
    assert @compose.dig("services", "db-admin") || @compose.dig("services", "adminer"),
           "compose.yaml must define 'db-admin' (Adminer) service on port 8081"
  end

  def test_docker_entrypoint_loads_queue_schema_when_solid_queue_tables_missing
    assert_match(/solid_queue_processes/, @entrypoint,
                 "blog/bin/docker-entrypoint must check if solid_queue_processes table exists")
    assert_match(/queue_schema\.rb/, @entrypoint,
                 "blog/bin/docker-entrypoint must load db/queue_schema.rb if solid_queue_processes is missing")
  end

  def test_docker_entrypoint_bootstraps_db_seed_when_admin_email_present
    assert_match(/GOOGLE_CLOUD_ACCOUNT/, @entrypoint,
                 "blog/bin/docker-entrypoint must check GOOGLE_CLOUD_ACCOUNT and run db:seed automatically")
    assert_match(/db:seed/, @entrypoint,
                 "blog/bin/docker-entrypoint must invoke db:seed so local Docker Compose creates the admin user out of the box")
  end

  def test_docker_entrypoint_sources_root_and_blog_dotenv_files
    assert_match(/\.\.\/\.env/, @entrypoint,
                 "blog/bin/docker-entrypoint must source ../.env when present")
  end
end
