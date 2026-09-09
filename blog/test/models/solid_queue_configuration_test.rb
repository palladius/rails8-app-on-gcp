# frozen_string_literal: true

require "test_helper"

class SolidQueueConfigurationTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  test "puma configuration references solid_queue plugin conditionally" do
    puma_config = File.read(Rails.root.join("config/puma.rb"))
    assert_includes puma_config, "plugin :solid_queue if ENV[\"SOLID_QUEUE_IN_PUMA\"]"
  end

  test "enqueued jobs can be executed by active worker or inline" do
    post = Post.create!(title: "Queue Test Post", body: "Testing solid queue execution")
    
    assert_enqueued_jobs 1, only: PodcastifierJob do
      PodcastifierJob.perform_later(post.id)
    end

    perform_enqueued_jobs

    post.reload
    assert post.podcast_audio_it.attached?, "Podcast audio should be attached after job execution"
  end
end
