require "test_helper"

class PodcastifierJobTest < ActiveJob::TestCase
  test "attaches podcast_audio_it to post" do
    post = Post.create!(title: "Test Podcast Post", body: "Short body for TTS test")
    assert_not post.podcast_audio_it.attached?

    PodcastifierJob.perform_now(post.id)
    post.reload

    assert post.podcast_audio_it.attached?
    assert_equal "podcast_it_#{post.id}.mp3", post.podcast_audio_it.filename.to_s
  end
end
