require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "cover_image url can be generated without raising SignedUrlUnavailable" do
    # Create a dummy post and attach a dummy file
    post = Post.create!(title: "Test Post")
    
    # We write a tiny dummy file to attach
    file_path = Rails.root.join("tmp", "dummy.txt")
    File.write(file_path, "dummy")
    
    # We manually create a Blob record to skip actually uploading the file to GCS
    # during the test setup, which would otherwise throw a PermissionDeniedError 
    # if using ADC without write access.
    blob = ActiveStorage::Blob.create!(
      key: "test_dummy_key.txt",
      filename: "dummy.txt",
      content_type: "text/plain",
      byte_size: 5,
      checksum: Digest::MD5.file(file_path).base64digest
    )
    
    # We want to catch the specific SignedUrlUnavailable error if it occurs.
    # We temporarily force the service to GCS (google_dev) so we actually test
    # the remote URL signing instead of the local Disk service.
    original_service = ActiveStorage::Blob.service
    begin
      # Force to the GCS service configured in storage.yml
      ActiveStorage::Blob.service = ActiveStorage::Service.configure(:google_dev, Rails.configuration.active_storage.service_configurations)
      
      url = blob.url
      assert_not_nil url, "URL should be generated successfully"
    rescue Google::Apis::ClientError => e
      if e.message.include?("PERMISSION_DENIED") && e.message.include?("signBlob")
        skip "Skipping GCS signed URL test: local ADC lacks iam.serviceAccounts.signBlob. " \
             "Grant roles/iam.serviceAccountTokenCreator on the Cloud Run SA or set " \
             "ACTIVE_STORAGE_SERVICE=local to use disk storage in dev."
      else
        raise e
      end
    rescue => e
      if e.class.name == "Google::Cloud::Storage::SignedUrlUnavailable" || 
         (e.class.name == "Google::Cloud::PermissionDeniedError" && e.message.include?("Invalid request"))
        
        flunk "ActiveStorage failed to generate a signed URL! Your local server is likely running without proper Google Service Account credentials (e.g. relying on your personal ADC which lacks a client_email). Ensure GOOGLE_APPLICATION_CREDENTIALS is set in .env and restart your server.\n\nOriginal Error: #{e.class.name}: #{e.message}"
      else
        raise e
      end
    ensure
      ActiveStorage::Blob.service = original_service
    end
  end
end
