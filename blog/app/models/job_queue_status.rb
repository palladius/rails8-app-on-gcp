# Counts what Solid Queue still has to do, for the stuck-jobs banner and /status.
#
# A failed job keeps `finished_at` nil, so counting unfinished jobs alone reports
# failed jobs as "pending" forever. Pending here means unfinished and not failed.
# `worker_alive` is true when a Solid Queue worker has sent a heartbeat recently,
# which tells a single-container deployment apart from one with a worker sidecar.
module JobQueueStatus
  Snapshot = Struct.new(:pending, :failed, :worker_alive, keyword_init: true)

  EMPTY = Snapshot.new(pending: 0, failed: 0, worker_alive: false).freeze

  def self.snapshot
    failed_job_ids = SolidQueue::FailedExecution.select(:job_id)

    Snapshot.new(
      pending: SolidQueue::Job.where(finished_at: nil).where.not(id: failed_job_ids).count,
      failed: SolidQueue::FailedExecution.count,
      worker_alive: SolidQueue::Process
        .where(kind: "Worker")
        .where("last_heartbeat_at > ?", SolidQueue.process_alive_threshold.ago)
        .exists?
    )
  rescue StandardError
    # No queue database (tests, SQLite without the queue schema): nothing to report.
    EMPTY
  end
end
