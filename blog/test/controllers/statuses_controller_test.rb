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
    assert json["run_env"].present?
    assert json["database"].present?
    assert json["storage"].present?
    assert json["ai"].present?
    assert json["jobs"].present?
  end
end
