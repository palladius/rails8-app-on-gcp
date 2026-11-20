require "test_helper"

class PodcastifierJobTest < ActiveJob::TestCase
  test "attaches podcast_audio_it to post" do
    post = Post.create!(title: "Test Podcast Post", body: "Short body for TTS test")
    assert_not post.podcast_audio_it.attached?

    with_env("GOOGLE_CLOUD_PROJECT" => nil) do
      stub_singleton(CloudTtsService, :access_token, nil) do
        PodcastifierJob.perform_now(post.id)
      end
    end
    post.reload

    assert post.podcast_audio_it.attached?
    assert_equal "podcast_it_#{post.id}.mp3", post.podcast_audio_it.filename.to_s
  end

  # Authored locally for bug reproduction (#199)
  test "skips synthesis if podcast_audio_it is already attached and discards missing posts" do
    post = Post.create!(title: "Already Has Audio", body: "Existing attachment.")
    post.podcast_audio_it.attach(io: StringIO.new("existing-mp3"), filename: "existing.mp3", content_type: "audio/mpeg")

    called = false
    stub_singleton(PodcastTranslationService, :translate_and_summarize, ->(*, **) { called = true }) do
      PodcastifierJob.perform_now(post.id)
    end
    assert_not called, "PodcastifierJob must not re-translate when podcast_audio_it is already attached"

    assert_nothing_raised { PodcastifierJob.perform_now(-1) }
  end

  test "translates English post to Italian before calling CloudTtsService" do
    post = Post.create!(
      title: "Modern Cloud Architecture with Rails 8",
      body: "Deploying multi-container sidecars on Google Cloud Run with Cloud SQL and private Cloud Storage."
    )
    captured_calls = []
    dummy_io = StringIO.new("fake-mp3-bytes")

    with_env("GOOGLE_CLOUD_PROJECT" => nil) do
      stub_singleton(CloudTtsService, :synthesize, ->(text:, **kwargs) {
        captured_calls << { text: text, kwargs: kwargs }
        dummy_io
      }) do
        PodcastifierJob.perform_now(post.id)
      end
    end

    assert_equal 1, captured_calls.size
    call = captured_calls.first
    assert_equal "it-IT", call[:kwargs][:language_code]
    assert_equal "it-IT-Wavenet-A", call[:kwargs][:voice]

    sent_text = call[:text]
    assert_includes sent_text, "Benvenuti al podcast"
    refute_includes sent_text, "Modern Cloud Architecture"
    refute_includes sent_text, "Deploying multi-container sidecars"
    assert post.reload.podcast_audio_it.attached?
  end

  test "forwards title, plain-text body, and translated script from PodcastTranslationService to CloudTtsService" do
    post = Post.create!(title: "Rails 8 on Cloud Run", body: "Sidecars and Solid Queue workers in production.")
    expected_script = "Benvenuti al podcast del blog! Oggi parliamo di Rails 8 su Cloud Run."
    received_args = nil
    captured_text = nil

    stub_singleton(PodcastTranslationService, :translate_and_summarize, ->(title:, body:) {
      received_args = { title: title, body: body }
      expected_script
    }) do
      stub_singleton(CloudTtsService, :synthesize, ->(text:, **_kwargs) {
        captured_text = text
        StringIO.new("fake-mp3-bytes")
      }) do
        PodcastifierJob.perform_now(post.id)
      end
    end

    assert_equal "Rails 8 on Cloud Run", received_args[:title]
    assert_includes received_args[:body], "Sidecars and Solid Queue"
    assert_equal expected_script, captured_text
  end

  private

  def with_env(envs)
    old = envs.keys.index_with { |k| ENV[k] }
    envs.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
    yield
  ensure
    old.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end
end
