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
end
