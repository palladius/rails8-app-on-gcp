# frozen_string_literal: true

require "test_helper"

class WorkshopAlertsTest < ActionDispatch::IntegrationTest
  setup do
    # Ensure at least one user exists so missing_admin alert does not distract
    User.find_or_create_by!(email_address: "admin@example.com") do |u|
      u.password = "password123"
    end
  end

  # =========================================================================
  # 1. SQL Ephemeral Database Alert
  # =========================================================================
  test "renders ephemeral database alert when running against local DB without Cloud SQL" do
    with_env("CLOUDSQL_INSTANCE" => nil, "DATABASE_URL" => nil) do
      get posts_url
      assert_response :success
      assert_select ".workshop-ephemeral-database-alert" do
        assert_select "strong", text: /Notice: Ephemeral Database Active/
        assert_select "a", text: /Why\? \(Ask AI\)/
      end
    end
  end

  test "suppresses ephemeral database alert when CLOUDSQL_INSTANCE is configured" do
    with_env("CLOUDSQL_INSTANCE" => "gcp-project:us-central1:rails-db") do
      get posts_url
      assert_response :success
      assert_select ".workshop-ephemeral-database-alert", count: 0
    end
  end

  # =========================================================================
  # 2. Storage Ephemeral Disk Alert
  # =========================================================================
  test "renders ephemeral storage alert when storage tier is :local" do
    stub_singleton(Nanobanana, :storage_tier, :local) do
      get posts_url
      assert_response :success
      assert_select ".workshop-ephemeral-storage-alert" do
        assert_select "strong", text: /Notice: Ephemeral Local Disk Storage Active/
        assert_select "a", text: /Why\? \(Ask AI\)/
      end
    end
  end

  test "suppresses ephemeral storage alert when storage tier is :gcs" do
    stub_singleton(Nanobanana, :storage_tier, :gcs) do
      get posts_url
      assert_response :success
      assert_select ".workshop-ephemeral-storage-alert", count: 0
    end
  end

  # =========================================================================
  # 3. GenAI Status Alert
  # =========================================================================
  test "renders AI fallback alert when Nanobanana is not available" do
    stub_singleton(Nanobanana, :available?, false) do
      get posts_url
      assert_response :success
      assert_select ".workshop-ai-fallback-alert" do
        assert_select "strong", text: /Notice: Nano Banana AI Cover in Fake Fallback Mode/
        assert_select "a", text: /Why\? \(Ask AI\)/
      end
    end
  end

  test "suppresses AI fallback alert when Nanobanana is available" do
    stub_singleton(Nanobanana, :available?, true) do
      get posts_url
      assert_response :success
      assert_select ".workshop-ai-fallback-alert", count: 0
    end
  end

  # =========================================================================
  # 4. Master Kill Switch
  # =========================================================================
  test "suppresses entire alerts hub when DISABLE_WORKSHOP_ALERTS is set" do
    with_env("DISABLE_WORKSHOP_ALERTS" => "true") do
      get posts_url
      assert_response :success
      assert_select ".workshop-alerts-hub", count: 0
      assert_select ".workshop-ephemeral-database-alert", count: 0
      assert_select ".workshop-ephemeral-storage-alert", count: 0
      assert_select ".workshop-ai-fallback-alert", count: 0
    end
  end

  private

  def with_env(env_hash)
    orig_env = {}
    env_hash.each do |k, v|
      orig_env[k] = ENV[k]
      ENV[k] = v
    end
    yield
  ensure
    orig_env.each do |k, v|
      ENV[k] = v
    end
  end
end
