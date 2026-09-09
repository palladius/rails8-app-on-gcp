require "test_helper"

class NanobananaUatMatrixTest < ActionView::TestCase
  include ActiveJob::TestHelper
  include ApplicationHelper

  SAMPLE_IMAGE = Rails.root.join("db/seeds/test_image_600x400.jpg")

  # 8 Possibilities in UAT Matrix:
  # Dimensions:
  #   1. Storage: Local (ephemeral disk) vs GCS
  #   2. AI / Credentials: Working Vertex AI vs Fake / Missing Credentials
  #   3. Image source: User upload vs Auto-generation

  # Comb 1: Local + Working AI + Upload
  test "UAT 1: Local Storage + Working Vertex AI + User Uploaded Image" do
    with_storage_tier(:local) do
      post = create_post_with_cover("Combo 1 - Local AI Upload", SAMPLE_IMAGE)
      assert_no_enqueued_jobs(only: GenerateCoverImageJob)
      assert post.cover_image.attached?
      assert_equal "test_image_600x400.jpg", post.cover_image.filename.to_s
      assert_provenance_ui(tier: :local)
    end
  end

  # Comb 2: Local + Working AI + No Upload (Generated)
  test "UAT 2: Local Storage + Working Vertex AI + Auto-generation" do
    with_storage_tier(:local) do
      vertex_result = Nanobanana::Result.new(
        data: File.binread(SAMPLE_IMAGE),
        content_type: "image/jpeg",
        source: :vertex
      )
      stub_singleton(Nanobanana, :available?, true) do
        stub_singleton(Nanobanana, :generate_image, vertex_result) do
          post = Post.create!(title: "Combo 2 - Local AI Gen", body: "Deploying Rails 8 on Cloud Run with Solid Queue.")
          GenerateCoverImageJob.perform_now(post.id)
          post.reload
          assert post.cover_image.attached?
          assert_equal "cover_#{post.id}_vertex_local.png", post.cover_image.filename.to_s
          assert_provenance_ui(tier: :local)
        end
      end
    end
  end

  # Comb 3: Local + Fake AI + Upload
  test "UAT 3: Local Storage + Fake AI (No Creds) + User Uploaded Image" do
    with_storage_tier(:local) do
      stub_singleton(Nanobanana, :available?, false) do
        post = create_post_with_cover("Combo 3 - Local Fake Upload", SAMPLE_IMAGE)
        assert_no_enqueued_jobs(only: GenerateCoverImageJob)
        assert post.cover_image.attached?
        assert_equal "test_image_600x400.jpg", post.cover_image.filename.to_s
        assert_provenance_ui(tier: :local)
      end
    end
  end

  # Comb 4: Local + Fake AI + No Upload (Fallback Generated)
  test "UAT 4: Local Storage + Fake AI (No Creds) + Auto-generation (Fallback)" do
    with_storage_tier(:local) do
      stub_singleton(Nanobanana, :available?, false) do
        stub_singleton(Nanobanana, :credentials, nil) do
          post = Post.create!(title: "Combo 4 - Local Fake Gen", body: "Deploying Rails 8 on Cloud Run with Solid Queue.")
          GenerateCoverImageJob.perform_now(post.id)
          post.reload
          assert post.cover_image.attached?
          assert_equal "cover_#{post.id}_fake_local.png", post.cover_image.filename.to_s
          assert_provenance_ui(tier: :local)
        end
      end
    end
  end

  # Comb 5: GCS + Working AI + Upload
  test "UAT 5: GCS + Working Vertex AI + User Uploaded Image" do
    with_storage_tier(:gcs) do
      post = create_post_with_cover("Combo 5 - GCS AI Upload", SAMPLE_IMAGE)
      assert_no_enqueued_jobs(only: GenerateCoverImageJob)
      assert post.cover_image.attached?
      assert_equal "test_image_600x400.jpg", post.cover_image.filename.to_s
      assert_provenance_ui(tier: :gcs)
    end
  end

  # Comb 6: GCS + Working AI + No Upload (Generated)
  test "UAT 6: GCS + Working Vertex AI + Auto-generation" do
    with_storage_tier(:gcs) do
      vertex_result = Nanobanana::Result.new(
        data: File.binread(SAMPLE_IMAGE),
        content_type: "image/jpeg",
        source: :vertex
      )
      stub_singleton(Nanobanana, :available?, true) do
        stub_singleton(Nanobanana, :generate_image, vertex_result) do
          post = Post.create!(title: "Combo 6 - GCS AI Gen", body: "Deploying Rails 8 on Cloud Run with Solid Queue.")
          GenerateCoverImageJob.perform_now(post.id)
          post.reload
          assert post.cover_image.attached?
          assert_equal "cover_#{post.id}_vertex_gcs.png", post.cover_image.filename.to_s
          assert_provenance_ui(tier: :gcs)
        end
      end
    end
  end

  # Comb 7: GCS + Fake AI + Upload
  test "UAT 7: GCS + Fake AI (No Creds) + User Uploaded Image" do
    with_storage_tier(:gcs) do
      stub_singleton(Nanobanana, :available?, false) do
        post = create_post_with_cover("Combo 7 - GCS Fake Upload", SAMPLE_IMAGE)
        assert_no_enqueued_jobs(only: GenerateCoverImageJob)
        assert post.cover_image.attached?
        assert_equal "test_image_600x400.jpg", post.cover_image.filename.to_s
        assert_provenance_ui(tier: :gcs)
      end
    end
  end

  # Comb 8: GCS + Fake AI + No Upload (Fallback Generated)
  test "UAT 8: GCS + Fake AI (No Creds) + Auto-generation (Fallback)" do
    with_storage_tier(:gcs) do
      stub_singleton(Nanobanana, :available?, false) do
        stub_singleton(Nanobanana, :credentials, nil) do
          post = Post.create!(title: "Combo 8 - GCS Fake Gen", body: "Deploying Rails 8 on Cloud Run with Solid Queue.")
          GenerateCoverImageJob.perform_now(post.id)
          post.reload
          assert post.cover_image.attached?
          assert_equal "cover_#{post.id}_fake_gcs.png", post.cover_image.filename.to_s
          assert_provenance_ui(tier: :gcs)
        end
      end
    end
  end

  private

  def create_post_with_cover(title, image_path)
    post = Post.new(title: title, body: "Post body for #{title}")
    post.cover_image.attach(io: File.open(image_path), filename: File.basename(image_path), content_type: "image/jpeg")
    post.save!
    post
  end

  def with_storage_tier(tier)
    stub_singleton(Nanobanana, :storage_tier, tier) do
      yield
    end
  end

  def assert_provenance_ui(tier:)
    if tier == :local
      assert_equal :local, storage_tier
      assert_equal "cover-image--local", cover_image_classes
      assert_includes cover_image_title, "ephemeral local disk: sad grayscale mode"
    else
      assert_equal :gcs, storage_tier
      assert_equal "", cover_image_classes
      assert_includes cover_image_title, "Google Cloud Storage"
    end
  end
end
