require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "returns native dev badge and custom tooltip when RAILS8_ENV_LAUNCH_MODE contains native story" do
    with_env("RAILS8_ENV_LAUNCH_MODE" => "Hello! I am the native app launched with bin/dev on local SQLite.") do
      info = launch_mode_info
      assert_equal "💻 Local Rails · SQLite", info[:badge]
      assert_equal "Hello! I am the native app launched with bin/dev on local SQLite.", info[:tooltip]
      assert_equal "#6366f1", info[:color]
    end
  end

  test "returns docker compose badge and tooltip when RAILS8_ENV_LAUNCH_MODE contains docker" do
    with_env("RAILS8_ENV_LAUNCH_MODE" => "Hello! I am the containerized app running on PostgreSQL via Docker Compose.") do
      info = launch_mode_info
      assert_equal "🐳 Docker Compose · Postgres", info[:badge]
      assert_equal "Hello! I am the containerized app running on PostgreSQL via Docker Compose.", info[:tooltip]
      assert_equal "#0284c7", info[:color]
    end
  end

  test "returns cloud run badge and tooltip when RAILS8_ENV_LAUNCH_MODE contains cloud run" do
    with_env("RAILS8_ENV_LAUNCH_MODE" => "Hello! I am running serverless on Google Cloud Run.") do
      info = launch_mode_info
      assert_equal "☁️ Google Cloud Run", info[:badge]
      assert_equal "Hello! I am running serverless on Google Cloud Run.", info[:tooltip]
      assert_equal "#059669", info[:color]
    end
  end

  test "auto-detects native dev fallback when RAILS8_ENV_LAUNCH_MODE is not set" do
    with_env("RAILS8_ENV_LAUNCH_MODE" => nil, "K_SERVICE" => nil, "DOCKER_CONTAINER" => nil) do
      info = launch_mode_info
      assert_equal "💻 Local Rails · SQLite", info[:badge]
      assert_includes info[:tooltip], "bin/dev"
      assert_equal "#6366f1", info[:color]
    end
  end

  private

  def with_env(envs)
    old_envs = envs.keys.index_with { |k| ENV[k] }
    envs.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
    yield
  ensure
    old_envs.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end
end
