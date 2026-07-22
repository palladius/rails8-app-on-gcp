require "test_helper"

class PostsImagesTest < ActionDispatch::IntegrationTest
  setup do
    @post = Post.create!(title: "Test Post", body: "With an image")
    @local_post = Post.create!(title: "Local Post", body: "With local image")
    
    file_path = Rails.root.join("tmp", "dummy.txt")
    File.write(file_path, "dummy")
    
    # We expect local_image to be defined and to use the local disk service
    @local_post.local_image.attach(io: File.open(file_path), filename: "dummy.txt")
  end

  test "local image is attached using local service" do
    assert @local_post.local_image.attached?
    assert_equal "DiskService", @local_post.local_image.blob.service.class.name.split("::").last
  end
end
