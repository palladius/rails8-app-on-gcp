require "test_helper"

class PostsImagesTest < ActionDispatch::IntegrationTest
  setup do
    @post = Post.create!(title: "Test Post", body: "With a cover image")
  end

  test "post model only has cover_image attachment (no local_image)" do
    assert @post.respond_to?(:cover_image), "Post should have cover_image attachment"
    assert_not @post.respond_to?(:local_image), "Post should NOT have local_image attachment"
  end

  test "cover_image is not attached by default" do
    assert_not @post.cover_image.attached?
  end
end
