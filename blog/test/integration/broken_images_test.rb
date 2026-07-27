require "test_helper"

class BrokenImagesTest < ActionDispatch::IntegrationTest
  setup do
    @post = Post.create!(title: "Remote Post", body: "With remote image")

    file_path = Rails.root.join("tmp", "dummy.txt")
    File.write(file_path, "dummy")

    # Remote (GCS) attachment
    @post.cover_image.attach(io: File.open(file_path), filename: "dummy.txt", content_type: "text/plain")
  end

  test "cover_image can generate URLs without SignedUrlUnavailable" do
    begin
      # Temporarily force the service to GCS to simulate the production/GCS environment
      original_service = ActiveStorage::Blob.service
      ActiveStorage::Blob.service = ActiveStorage::Service.configure(:google_dev, Rails.configuration.active_storage.service_configurations)

      ActiveStorage::Current.url_options = { host: "https://example.com" }

      # Test the cover image URL generation
      remote_url = nil
      assert_nothing_raised do
        remote_url = @post.cover_image.url
      end
      assert_not_nil remote_url

    rescue => e
      if e.class.name == "Google::Cloud::Storage::SignedUrlUnavailable" ||
         (e.class.name == "Google::Cloud::PermissionDeniedError" && e.message.include?("Invalid request"))

        flunk "ActiveStorage failed to generate a signed URL! This perfectly reproduces the broken remote image error you saw.\nError: #{e.class.name}: #{e.message}"
      else
        raise e
      end
    ensure
      ActiveStorage::Blob.service = original_service
    end
  end
end
