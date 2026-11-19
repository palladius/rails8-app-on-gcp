require "test_helper"

class StuckJobsWarningTest < ActionDispatch::IntegrationTest
  def snapshot(pending: 0, failed: 0, worker_alive: false)
    JobQueueStatus::Snapshot.new(pending: pending, failed: failed, worker_alive: worker_alive)
  end

  test "does not render stuck jobs warning when there are no pending jobs" do
    get posts_url
    assert_response :success
    assert_select ".stuck-jobs-alert", count: 0
  end

  test "renders pedagogical warning when no worker is polling the queue" do
    stub_singleton(JobQueueStatus, :snapshot, snapshot(pending: 1)) do
      get posts_url
    end

    assert_response :success
    assert_select ".stuck-jobs-alert" do
      assert_select "strong", text: /1 background job currently pending execution/
      assert_select ".stuck-jobs-reason", text: /not running in this single-container deployment/
      assert_select "a", text: /Why\? \(Ask AI\)/
    end
  end

  test "does not blame a single-container deployment when a worker is alive" do
    stub_singleton(JobQueueStatus, :snapshot, snapshot(pending: 2, worker_alive: true)) do
      get posts_url
    end

    assert_select ".stuck-jobs-alert" do
      assert_select ".stuck-jobs-reason", text: /worker is running/
      assert_select "a", text: /Why\? \(Ask AI\)/, count: 0
    end
    assert_no_match(/single-container/, response.body)
  end

  test "reports failed jobs as failed, not as pending" do
    stub_singleton(JobQueueStatus, :snapshot, snapshot(failed: 1, worker_alive: true)) do
      get posts_url
    end

    assert_select ".stuck-jobs-alert" do
      assert_select ".failed-jobs-notice", text: /1 background job failed/
    end
    assert_no_match(/pending execution/, response.body)
  end
end
