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
end
