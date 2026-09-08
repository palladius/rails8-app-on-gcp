require "test_helper"

class PostTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "creating a post without a cover enqueues the Nano Banana job" do
    assert_enqueued_with(job: GenerateCoverImageJob) do
      Post.create!(title: "No cover here", body: "Somebody please draw me a banana.")
    end
  end

  test "creating a post with a cover attached does not enqueue the job" do
    post = Post.new(title: "Already illustrated", body: "I brought my own picture.")
    post.cover_image.attach(io: File.open(Rails.root.join("db/seeds/test_image_600x400.jpg")), filename: "mine.jpg", content_type: "image/jpeg")

    assert_no_enqueued_jobs(only: GenerateCoverImageJob) do
      post.save!
    end
  end
end
