# frozen_string_literal: true

# Authored locally for bug reproduction (Issue #197)
require "test_helper"
require "rake"

class SolidQueueMaintenanceTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("solid_queue:clear_failed")
  end

  test "solid_queue:clear_failed discards all failed executions" do
    assert Rake::Task.task_defined?("solid_queue:clear_failed"),
           "Expected rake task solid_queue:clear_failed to be defined"

    discarded = []
    exec1 = Object.new
    exec1.define_singleton_method(:discard) { discarded << :exec1 }
    exec2 = Object.new
    exec2.define_singleton_method(:discard) { discarded << :exec2 }

    stub_singleton(SolidQueue::FailedExecution, :find_each, ->(&block) { [ exec1, exec2 ].each(&block) }) do
      Rake::Task["solid_queue:clear_failed"].invoke
    end

    assert_equal [ :exec1, :exec2 ], discarded
  ensure
    Rake::Task["solid_queue:clear_failed"].reenable if Rake::Task.task_defined?("solid_queue:clear_failed")
  end

  test "solid_queue:retry_failed retries all failed executions" do
    assert Rake::Task.task_defined?("solid_queue:retry_failed"),
           "Expected rake task solid_queue:retry_failed to be defined"

    retried = []
    exec1 = Object.new
    exec1.define_singleton_method(:retry) { retried << :exec1 }
    exec2 = Object.new
    exec2.define_singleton_method(:retry) { retried << :exec2 }

    stub_singleton(SolidQueue::FailedExecution, :find_each, ->(&block) { [ exec1, exec2 ].each(&block) }) do
      Rake::Task["solid_queue:retry_failed"].invoke
    end

    assert_equal [ :exec1, :exec2 ], retried
  ensure
    Rake::Task["solid_queue:retry_failed"].reenable if Rake::Task.task_defined?("solid_queue:retry_failed")
  end
end
