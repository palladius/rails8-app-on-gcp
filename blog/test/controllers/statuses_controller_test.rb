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
<<<<<<< HEAD
    assert json["quest"].present?
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
end
