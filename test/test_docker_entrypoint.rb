# frozen_string_literal: true

require "minitest/autorun"
require "open3"

# Issue #168: blog/bin/docker-entrypoint called `rails db:prepare:queue|cache|cable`, which do
# not exist ("Unrecognized command", 3 error lines per boot in Cloud Logging). They looked
# like no-ops-by-accident, but they were hiding a real need: on Cloud Run all four databases
# share ONE Postgres database that already exists, so plain `db:prepare` never loads
# db/{queue,cache,cable}_schema.rb and the solid_* tables are missing.
class DockerEntrypointTest < Minitest::Test
  BLOG_DIR = File.expand_path("../blog", __dir__)
  ENTRYPOINT = File.join(BLOG_DIR, "bin", "docker-entrypoint")

  def test_does_not_call_nonexistent_per_database_prepare_tasks
    script = File.read(ENTRYPOINT)
    refute_match(/db:prepare:(queue|cache|cable)/, script,
                 "Rails has no db:prepare:<name> task (only db:create:<name> / db:migrate:<name>)")
  end

  def test_does_not_hide_schema_errors
    script = File.read(ENTRYPOINT)
    refute_match(/db:prepare[^\n]*2>\/dev\/null/, script)
  end

  # Needs an EMPTY, already-existing Postgres database (like Cloud SQL after Terraform), e.g.
  #   docker run -d --rm -e POSTGRES_PASSWORD=pw -e POSTGRES_DB=app -p 127.0.0.1:55432:5432 postgres:16-alpine
  #   ENTRYPOINT_TEST_DATABASE_URL=postgresql://postgres:pw@127.0.0.1:55432/app ruby test/test_docker_entrypoint.rb
  def test_boot_on_shared_postgres_creates_every_solid_table_without_errors
    url = ENV["ENTRYPOINT_TEST_DATABASE_URL"]
    skip "set ENTRYPOINT_TEST_DATABASE_URL to an empty Postgres database to run this" if url.to_s.empty?

    env = { "RAILS_ENV" => "production", "SECRET_KEY_BASE_DUMMY" => "1", "DATABASE_URL" => url,
            "GOOGLE_CLOUD_ACCOUNT" => nil, "ADMIN_EMAIL" => nil }
    _out, err, status = Open3.capture3(env, ENTRYPOINT, "echo", "rails", "server", chdir: BLOG_DIR)
    assert status.success?, err
    refute_includes err, "Unrecognized command"

    tables, _e, _s = Open3.capture3("psql", url, "-Atc", "select tablename from pg_tables where schemaname='public'")
    %w[solid_queue_processes solid_cache_entries solid_cable_messages].each do |t|
      assert_includes tables.split("\n"), t, "#{t} must exist after the entrypoint prepared the databases"
    end
  end

  # --- first-boot hardening (PR #179 review) -------------------------------------------------
  # Both need a Postgres where the test can create/drop databases (ENTRYPOINT_TEST_DATABASE_URL).

  def admin_and_fresh_urls(url)
    name = "entrypoint_test_#{Process.pid}_#{rand(10_000)}"
    [url.sub(%r{/[^/]+\z}, "/postgres"), url.sub(%r{/[^/]+\z}, "/#{name}"), name]
  end

  def server_env(url)
    { "RAILS_ENV" => "production", "SECRET_KEY_BASE_DUMMY" => "1", "DATABASE_URL" => url,
      "GOOGLE_CLOUD_ACCOUNT" => nil, "ADMIN_EMAIL" => nil }
  end

  def solid_tables(url)
    out, _e, _s = Open3.capture3("psql", url, "-Atc", "select tablename from pg_tables where schemaname='public'")
    out.split("\n")
  end

  # On Cloud Run `web` and `worker` boot at the same time against the same database. Both used to
  # load queue_schema.rb concurrently (create_table force: :cascade): the loser died with
  # PG::DuplicateObject. A database-level lock must serialize them.
  def test_web_and_worker_booting_concurrently_do_not_collide_on_the_schema_load
    url = ENV["ENTRYPOINT_TEST_DATABASE_URL"]
    skip "set ENTRYPOINT_TEST_DATABASE_URL to run this" if url.to_s.empty?
    admin, fresh, name = admin_and_fresh_urls(url)
    system("psql", admin, "-qc", "create database #{name}", out: File::NULL)
    begin
      web = Thread.new { Open3.capture3(server_env(fresh), ENTRYPOINT, "echo", "rails", "server", chdir: BLOG_DIR) }
      worker = Thread.new { Open3.capture3(server_env(fresh), ENTRYPOINT, "echo", "bin/rails", "solid_queue:start", chdir: BLOG_DIR) }
      results = [web.value, worker.value]
      results.each do |out, err, status|
        assert status.success?, err
        refute_match(/WARNING|DuplicateObject|aborted/, out + err)
      end
      %w[solid_queue_processes solid_queue_jobs solid_cache_entries solid_cable_messages].each do |t|
        assert_includes solid_tables(fresh), t
      end
    ensure
      system("psql", admin, "-qc", "drop database if exists #{name}", out: File::NULL)
    end
  end

  # If the database itself does not exist yet, the helper used to skip (NoDatabaseError), so
  # db:prepare created it and then died seeding before the solid_queue tables existed.
  def test_boot_creates_a_missing_database_and_the_solid_tables
    url = ENV["ENTRYPOINT_TEST_DATABASE_URL"]
    skip "set ENTRYPOINT_TEST_DATABASE_URL to run this" if url.to_s.empty?
    admin, fresh, name = admin_and_fresh_urls(url)
    begin
      _out, err, status = Open3.capture3(server_env(fresh), ENTRYPOINT, "echo", "rails", "server", chdir: BLOG_DIR)
      assert status.success?, err
      %w[solid_queue_processes solid_cache_entries solid_cable_messages posts].each do |t|
        assert_includes solid_tables(fresh), t
      end
    ensure
      system("psql", admin, "-qc", "drop database if exists #{name}", out: File::NULL)
    end
  end

  def psql_value(url, sql)
    out, _e, _s = Open3.capture3("psql", url, "-Atc", sql)
    out.strip
  end

  # FL008-12: the Step 6 `rails-migrate` Cloud Run Job runs `./bin/rails db:prepare db:seed` through
  # this entrypoint (no --command override) against a brand-new Cloud SQL database. Seeding enqueues
  # Solid Queue jobs, so the Solid schemas must exist first, and re-running the job must not wipe the
  # queue (the old `db:schema:load:queue` did: `create_table force: :cascade`).
  def test_migrate_job_prepares_and_seeds_a_fresh_database_and_is_safe_to_rerun
    url = ENV["ENTRYPOINT_TEST_DATABASE_URL"]
    skip "set ENTRYPOINT_TEST_DATABASE_URL to run this" if url.to_s.empty?
    admin, fresh, name = admin_and_fresh_urls(url)
    system("psql", admin, "-qc", "create database #{name}", out: File::NULL)
    env = server_env(fresh).merge("GOOGLE_CLOUD_ACCOUNT" => "student@example.com", "ACTIVE_STORAGE_SERVICE" => "local")
    job = [ENTRYPOINT, "./bin/rails", "db:prepare", "db:seed"]
    begin
      out, err, status = Open3.capture3(env, *job, chdir: BLOG_DIR)
      assert status.success?, "first run failed:\n#{out}\n#{err}"
      %w[solid_queue_jobs solid_cache_entries solid_cable_messages posts users].each do |t|
        assert_includes solid_tables(fresh), t
      end
      assert_equal "1", psql_value(fresh, "select count(*) from users where email_address = 'student@example.com'")

      system("psql", fresh, "-qc", "insert into solid_queue_jobs (queue_name, class_name, priority, created_at, updated_at) " \
                                   "values ('default', 'Fl008SentinelJob', 0, now(), now())", out: File::NULL)
      out, err, status = Open3.capture3(env, *job, chdir: BLOG_DIR)
      assert status.success?, "re-run failed:\n#{out}\n#{err}"
      assert_equal "1", psql_value(fresh, "select count(*) from solid_queue_jobs where class_name = 'Fl008SentinelJob'"),
                   "re-running the migrate job must not wipe pending Solid Queue jobs"
      assert_equal "1", psql_value(fresh, "select count(*) from users where email_address = 'student@example.com'")
    ensure
      system("psql", admin, "-qc", "drop database if exists #{name}", out: File::NULL)
    end
  end
end
