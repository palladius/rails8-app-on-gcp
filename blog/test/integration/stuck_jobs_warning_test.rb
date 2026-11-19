require "test_helper"

class StuckJobsWarningTest < ActionDispatch::IntegrationTest
  test "does not render stuck jobs warning when there are no pending jobs" do
    with_solid_queue_counts(ready: 0, failed: 0) do
      get posts_url
      assert_response :success
      assert_select ".stuck-jobs-alert", count: 0
      assert_select ".failed-jobs-alert", count: 0
    end
  end

  test "renders pedagogical warning when solid queue has ready jobs" do
    with_solid_queue_counts(ready: 1, failed: 0) do
      get posts_url
      assert_response :success
      assert_select ".stuck-jobs-alert" do
        assert_select "strong", text: /1 background job currently pending execution/
        assert_select "a", text: /Why\? \(Ask AI\)/
      end
      assert_select ".failed-jobs-alert", count: 0
    end
  end

  # Authored locally for bug reproduction (Issue #197)
  test "does not render missing-worker warning and renders failed jobs alert when only failed executions exist" do
    with_solid_queue_counts(ready: 0, failed: 1, unfinished_jobs: 1) do
      get posts_url
      assert_response :success
      assert_select ".stuck-jobs-alert", count: 0
      assert_select ".failed-jobs-alert", count: 1 do
        assert_select "strong", text: /1 background job failed execution/
        assert_select "a", text: /Why\? \(Ask AI\)/
      end
    end
  end

  # Authored locally for bug reproduction (Issue #197)
  test "renders neither warning when a job is actively claimed and running" do
    with_solid_queue_counts(ready: 0, failed: 0, unfinished_jobs: 1) do
      get posts_url
      assert_response :success
      assert_select ".stuck-jobs-alert", count: 0
      assert_select ".failed-jobs-alert", count: 0
    end
  end

  # Authored locally for bug reproduction (Issue #197)
  test "renders pending and failed alerts independently when both ready and failed executions exist" do
    with_solid_queue_counts(ready: 2, failed: 1, unfinished_jobs: 3) do
      get posts_url
      assert_response :success
      assert_select ".stuck-jobs-alert" do
        assert_select "strong", text: /2 background jobs currently pending execution/
      end
      assert_select ".failed-jobs-alert" do
        assert_select "strong", text: /1 background job failed execution/
      end
    end
  end

  private

  def with_solid_queue_counts(ready:, failed:, unfinished_jobs: ready + failed)
    dummy_relation = Object.new
    dummy_relation.define_singleton_method(:count) { unfinished_jobs }
    dummy_relation.define_singleton_method(:where) { |*| dummy_relation }

    stub_singleton(SolidQueue::Job, :where, ->(*_args) { dummy_relation }) do
      stub_singleton(SolidQueue::ReadyExecution, :count, ready) do
        stub_singleton(SolidQueue::FailedExecution, :count, failed) do
          yield
        end
      end
    end
  end
end
