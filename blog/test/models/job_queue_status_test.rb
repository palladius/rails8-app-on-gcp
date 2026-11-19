require "test_helper"

class JobQueueStatusTest < ActiveSupport::TestCase
  test "reports an empty queue when the queue database is unavailable" do
    stub_singleton(SolidQueue::FailedExecution, :select, ->(*) { raise ActiveRecord::StatementInvalid, "no such table" }) do
      snapshot = JobQueueStatus.snapshot

      assert_equal 0, snapshot.pending
      assert_equal 0, snapshot.failed
      assert_equal false, snapshot.worker_alive
    end
  end
end
