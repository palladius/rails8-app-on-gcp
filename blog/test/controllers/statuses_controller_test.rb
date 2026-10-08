require "test_helper"

class StatusesControllerTest < ActionDispatch::IntegrationTest
  test "should get status page as HTML without authentication" do
    get status_url
    assert_response :success
    assert_select "h1", text: /System Telemetry & Workshop Status/
    assert_select "span", text: /Compute & Runtime/
    assert_select "span", text: /Database Persistence/
    assert_select "span", text: /ActiveStorage Blobs/
    assert_select "span", text: /Nano Banana AI Cover/
    assert_select "span", text: /Solid Queue Jobs/
  end

  test "should get status as JSON" do
    get status_url(format: :json)
    assert_response :success
    json = JSON.parse(response.body)
    assert json["system"].present?
    assert_includes json["system"], "blobs_count"
    assert_includes json["system"], "attachments_count"
    assert json["run_env"].present?
    assert json["database"].present?
    assert json["storage"].present?
    assert_includes json["storage"], "blobs_count"
    assert json["ai"].present?
    assert json["jobs"].present?
    assert json["quest"].present?
    assert_includes response.headers["Cache-Control"], "private"
  end

  test "should return quest status with step_8_completed false when STEP_8_GHI is not set" do
    old_val = ENV["STEP_8_GHI"]
    ENV.delete("STEP_8_GHI")
    begin
      get status_url(format: :json)
      assert_response :success
      json = JSON.parse(response.body)
      assert_equal false, json.dig("quest", "step_8_completed")
      assert_nil json.dig("quest", "ghi_issue")
      assert_nil json.dig("quest", "ghi_url")
    ensure
      ENV["STEP_8_GHI"] = old_val if old_val
    end
  end

  test "should parse STEP_8_GHI numeric string and return canonical issue URL" do
    old_val = ENV["STEP_8_GHI"]
    ENV["STEP_8_GHI"] = "83"
    begin
      get status_url(format: :json)
      assert_response :success
      json = JSON.parse(response.body)
      assert_equal true, json.dig("quest", "step_8_completed")
      assert_equal 83, json.dig("quest", "ghi_issue")
      assert_equal "https://github.com/palladius/rails8-app-on-gcp/issues/83", json.dig("quest", "ghi_url")
    ensure
      ENV.delete("STEP_8_GHI")
      ENV["STEP_8_GHI"] = old_val if old_val
    end
  end

  test "should parse STEP_8_GHI full URL and return canonical issue URL and number" do
    old_val = ENV["STEP_8_GHI"]
    ENV["STEP_8_GHI"] = "https://github.com/palladius/rails8-app-on-gcp/issues/83"
    begin
      get status_url(format: :json)
      assert_response :success
      json = JSON.parse(response.body)
      assert_equal true, json.dig("quest", "step_8_completed")
      assert_equal 83, json.dig("quest", "ghi_issue")
      assert_equal "https://github.com/palladius/rails8-app-on-gcp/issues/83", json.dig("quest", "ghi_url")
    ensure
      ENV.delete("STEP_8_GHI")
      ENV["STEP_8_GHI"] = old_val if old_val
    end
  end

  test "storage configuration defines google_prod and google alias" do
    storage_config = YAML.safe_load(ERB.new(File.read(Rails.root.join("config/storage.yml"))).result, aliases: true)
    assert storage_config["google_prod"].present?, "Expected google_prod to be defined in storage.yml"
    assert storage_config["google"].present?, "Expected google alias to be defined in storage.yml"
    assert_equal "GCS", storage_config["google"]["service"]
    assert_equal storage_config["google_prod"]["bucket"], storage_config["google"]["bucket"]
  end

  test "should infer workshop_step number 5, 6, and 7 based on telemetry" do
    controller = StatusesController.new

    # Step 5: Cloud SQL connected, storage is local
    controller.instance_variable_set(:@db_status, { tier: :cloud_sql })
    controller.instance_variable_set(:@storage_status, { tier: :local })
    controller.instance_variable_set(:@ai_status, { active: false })
    assert_equal 5, controller.send(:infer_workshop_step)[:number]

    # Step 6: Cloud Run + Cloud SQL + GCS, non-AI baseline
    begin
      old_k_service = ENV["K_SERVICE"]
      ENV["K_SERVICE"] = "blog"

      controller.instance_variable_set(:@db_status, { tier: :cloud_sql })
      controller.instance_variable_set(:@storage_status, { tier: :gcs })
      controller.instance_variable_set(:@ai_status, { active: false })
      assert_equal 6, controller.send(:infer_workshop_step)[:number]

      # Step 7: Cloud Run + Cloud SQL + GCS + active GenAI
      controller.instance_variable_set(:@db_status, { tier: :cloud_sql })
      controller.instance_variable_set(:@storage_status, { tier: :gcs })
      controller.instance_variable_set(:@ai_status, { active: true })
      assert_equal 7, controller.send(:infer_workshop_step)[:number]
    ensure
      ENV["K_SERVICE"] = old_k_service
    end
  end

  test "safe_environment masks PII emails for GOOGLE_CLOUD_ACCOUNT and ADMIN_EMAIL" do
    old_account = ENV["GOOGLE_CLOUD_ACCOUNT"]
    old_email = ENV["ADMIN_EMAIL"]
    ENV["GOOGLE_CLOUD_ACCOUNT"] = "settilorenzo97@gmail.com"
    ENV["ADMIN_EMAIL"] = "ricc@google.com"
    begin
      get status_url(format: :json)
      assert_response :success
      json = JSON.parse(response.body)
      safe_env = json["safe_environment"]
      assert safe_env.is_a?(Array)

      account_entry = safe_env.find { |e| e["key"] == "GOOGLE_CLOUD_ACCOUNT" }
      assert account_entry.present?
      assert_equal "se***97@gmail.com", account_entry["value"]
      assert_equal true, account_entry["is_set"]
      assert_equal false, account_entry["is_secret"]
      assert_equal true, account_entry["is_pii"]

      # Short local parts (<= 4 chars) only reveal their first character
      admin_entry = safe_env.find { |e| e["key"] == "ADMIN_EMAIL" }
      assert admin_entry.present?
      assert_equal "r***@google.com", admin_entry["value"]
      assert_equal true, admin_entry["is_set"]
      assert_equal false, admin_entry["is_secret"]
      assert_equal true, admin_entry["is_pii"]

      project_entry = safe_env.find { |e| e["key"] == "GOOGLE_CLOUD_PROJECT" }
      assert_equal false, project_entry["is_pii"]
    ensure
      ENV["GOOGLE_CLOUD_ACCOUNT"] = old_account
      ENV["ADMIN_EMAIL"] = old_email
    end
  end

  test "mask_pii_email never reveals most of a short or medium local part" do
    controller = StatusesController.new
    assert_equal "a***@example.com", controller.send(:mask_pii_email, "abc@example.com")
    assert_equal "j***@example.com", controller.send(:mask_pii_email, "j@example.com")
    assert_equal "a***e@example.com", controller.send(:mask_pii_email, "abcde@example.com")
    assert_equal "se***97@gmail.com", controller.send(:mask_pii_email, "settilorenzo97@gmail.com")
    assert_equal "not-an-email", controller.send(:mask_pii_email, "not-an-email")
  end

  test "safe_environment includes APP_ADMIN_PASSWORD and masks secrets with a fixed-length mask (no length oracle)" do
    old_app_pw = ENV["APP_ADMIN_PASSWORD"]
    old_admin_pw = ENV["ADMIN_PASSWORD"]
    ENV["APP_ADMIN_PASSWORD"] = "SecretPassword123"
    ENV["ADMIN_PASSWORD"] = "FallbackPass"
    begin
      get status_url(format: :json)
      assert_response :success
      json = JSON.parse(response.body)
      safe_env = json["safe_environment"]

      app_pw_entry = safe_env.find { |e| e["key"] == "APP_ADMIN_PASSWORD" }
      assert app_pw_entry.present?
      assert_equal true, app_pw_entry["is_secret"]
      assert_equal true, app_pw_entry["is_set"]
      assert_equal StatusesController::SECRET_MASK, app_pw_entry["value"]

      admin_pw_entry = safe_env.find { |e| e["key"] == "ADMIN_PASSWORD" }
      assert admin_pw_entry.present?
      assert_equal true, admin_pw_entry["is_secret"]
      assert_equal true, admin_pw_entry["is_set"]
      # Secrets of different lengths (17 vs 12 chars) must render identically
      assert_equal app_pw_entry["value"], admin_pw_entry["value"]
      refute_includes response.body, "SecretPassword123"
      refute_includes response.body, "FallbackPass"
    ensure
      ENV["APP_ADMIN_PASSWORD"] = old_app_pw
      ENV["ADMIN_PASSWORD"] = old_admin_pw
    end
  end
end
