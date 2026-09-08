require "test_helper"

class GenerateCoverImageJobTest < ActiveJob::TestCase
  include ActionCable::TestHelper

  setup do
    @post = Post.create!(title: "Rails 8 on Cloud Run", body: "Deploying a blog with Solid Queue and GCS.")
    clear_enqueued_jobs
  end

  test "attaches a stamped fake cover when Vertex AI is not available" do
    with_env("GOOGLE_CLOUD_PROJECT" => nil, "GCP_PROJECT_ID" => nil) do
      GenerateCoverImageJob.perform_now(@post.id)
    end

    @post.reload
    assert @post.cover_image.attached?
    assert_equal "cover_#{@post.id}_fake_local.png", @post.cover_image.filename.to_s
    assert_equal "image/png", @post.cover_image.content_type
    assert_operator @post.cover_image.byte_size, :>, 1000
  end

  test "is a no-op when the post already has a cover image" do
    @post.cover_image.attach(io: File.open(Rails.root.join("db/seeds/test_image_600x400.jpg")), filename: "mine.jpg", content_type: "image/jpeg")
    blob_id = @post.cover_image.blob.id

    assert_no_difference("ActiveStorage::Blob.count") do
      GenerateCoverImageJob.perform_now(@post.id)
    end
    assert_equal blob_id, @post.reload.cover_image.blob.id
    assert_equal "mine.jpg", @post.cover_image.filename.to_s
  end

  test "uses the Vertex AI image when generation succeeds" do
    result = Nanobanana::Result.new(data: File.binread(Rails.root.join("db/seeds/test_image_600x400.jpg")), content_type: "image/jpeg", source: :vertex)

    stub_singleton(Nanobanana, :generate_image, result) do
      GenerateCoverImageJob.perform_now(@post.id)
    end

    assert_equal "cover_#{@post.id}_vertex_local.png", @post.reload.cover_image.filename.to_s
  end

  test "builds the prompt from title and plain-text body" do
    prompts = []
    fake = fake_result
    stub_singleton(Nanobanana, :generate_image, ->(prompt) { prompts << prompt; fake }) do
      GenerateCoverImageJob.perform_now(@post.id)
    end

    assert_equal 1, prompts.size
    assert_match(/Rails 8 on Cloud Run/, prompts.first)
    assert_match(/Solid Queue/, prompts.first)
    assert_no_match(/<div/, prompts.first)
  end

  test "handles unintelligible posts with the Modena fallback prompt" do
    post = Post.create!(title: "qwerty", body: "asdf")
    prompts = []
    fake = fake_result
    stub_singleton(Nanobanana, :generate_image, ->(prompt) { prompts << prompt; fake }) do
      GenerateCoverImageJob.perform_now(post.id)
    end

    assert_match(/Modena/, prompts.first)
    assert post.reload.cover_image.attached?
  end

  test "broadcasts a refresh to the post stream" do
    with_env("GOOGLE_CLOUD_PROJECT" => nil, "GCP_PROJECT_ID" => nil) do
      assert_broadcasts(@post.to_gid_param, 1) do
        GenerateCoverImageJob.perform_now(@post.id)
      end
    end
  end

  test "discards jobs for deleted posts" do
    id = @post.id
    @post.destroy!
    assert_nothing_raised { GenerateCoverImageJob.perform_now(id) }
  end

  private

  def fake_result
    Nanobanana::Result.new(data: File.binread(Nanobanana::FAKE_COVER), content_type: "image/png", source: :fake)
  end

  def with_env(envs)
    old = envs.keys.index_with { |k| ENV[k] }
    envs.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
    yield
  ensure
    old.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end
end
