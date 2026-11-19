# frozen_string_literal: true

namespace :solid_queue do
  desc "Discard all failed Solid Queue executions"
  task clear_failed: :environment do
    count = 0
    SolidQueue::FailedExecution.find_each do |execution|
      execution.discard
      count += 1
    end
    puts "Discarded #{count} failed Solid Queue execution(s)."
  end

  desc "Retry all failed Solid Queue executions"
  task retry_failed: :environment do
    count = 0
    SolidQueue::FailedExecution.find_each do |execution|
      execution.retry
      count += 1
    end
    puts "Retried #{count} failed Solid Queue execution(s)."
  end
end
