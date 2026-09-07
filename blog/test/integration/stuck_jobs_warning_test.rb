require "test_helper"

class StuckJobsWarningTest < ActionDispatch::IntegrationTest
  test "does not render stuck jobs warning when there are no pending jobs" do
    get posts_url
    assert_response :success
    assert_select ".stuck-jobs-alert", count: 0
  end

  test "renders pedagogical warning when solid queue has pending jobs" do
    # Temporarily override SolidQueue::Job.where
    original_singleton = SolidQueue::Job.singleton_class
    dummy_relation = Object.new
    def dummy_relation.count; 1; end

    original_singleton.class_eval do
      alias_method :orig_where, :where
      define_method(:where) { |*args| dummy_relation }
    end

    begin
      get posts_url
      assert_response :success
      assert_select ".stuck-jobs-alert" do
        assert_select "strong", text: /1 background job currently pending execution/
        assert_select "a", text: /Why\? \(Ask AI\)/
      end
    ensure
      original_singleton.class_eval do
        alias_method :where, :orig_where
        remove_method :orig_where
      end
    end
  end
end
