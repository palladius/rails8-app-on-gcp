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

  test "storage tier is local under the test Disk service" do
    assert_equal :local, storage_tier
    assert_equal "cover-image--local", cover_image_classes
    assert_equal "post-show__hero-img cover-image--local", cover_image_classes("post-show__hero-img")
    assert_match(/grayscale/, cover_image_title)
  end

  test "storage tier is gcs for google services and covers keep their colors" do
    with_storage_service(:google_test) do
      assert_equal :gcs, storage_tier
      assert_equal "", cover_image_classes
      assert_equal "post-show__hero-img", cover_image_classes("post-show__hero-img")
      assert_match(/Cloud Storage/, cover_image_title)
    end
  end

  private

  def with_storage_service(name)
    previous = Rails.configuration.active_storage.service
    Rails.configuration.active_storage.service = name
    yield
  ensure
    Rails.configuration.active_storage.service = previous
  end

  def with_env(envs)
    old_envs = envs.keys.index_with { |k| ENV[k] }
    envs.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
    yield
  ensure
    old_envs.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end
end
