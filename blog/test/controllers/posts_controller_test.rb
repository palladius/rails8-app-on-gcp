require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:one)
    sign_in_as(users(:one))
  end

  test "should get index" do
    get posts_url
    assert_response :success
  end

  test "should get index without authentication" do
    sign_out
    get posts_url
    assert_response :success
  end

  test "should get show without authentication" do
    sign_out
    get post_url(@post)
    assert_response :success
  end

  test "should get new" do
    get new_post_url
    assert_response :success
  end

  test "should create post" do
    assert_difference("Post.count") do
      post posts_url, params: { post: { body: @post.body, title: @post.title } }
    end

    assert_redirected_to post_url(Post.last)
  end

  test "should show post" do
    get post_url(@post)
    assert_response :success
  end

  test "should show post with unresolvable local image in ActionText body without 500 crash" do
    @post.update!(body: '<action-text-attachment url="../out/both_starwars_world.png" content-type="image/png" caption="Star Wars"></action-text-attachment>')
    get post_url(@post)
    assert_response :success
    assert_select "img.attachment__broken-image[src=?]", "../out/both_starwars_world.png"
    assert_select "figcaption.attachment__caption", text: "Star Wars"
  end

  test "should show post with external remote image in ActionText body" do
    @post.update!(body: '<action-text-attachment url="https://example.com/starwars.png" content-type="image/png"></action-text-attachment>')
    get post_url(@post)
    assert_response :success
    assert_select "img[src=?]", "https://example.com/starwars.png"
  end

  test "rescues from Propshaft::MissingAssetError with 404" do
    PostsController.class_eval do
      def missing_asset_action
        raise Propshaft::MissingAssetError.new("missing.png")
      end
    end
    Rails.application.routes.draw do
      get "test_missing_asset", to: "posts#missing_asset_action"
    end

    get "/test_missing_asset"
    assert_response :not_found
  ensure
    Rails.application.reload_routes!
  end

  test "should get edit" do
    get edit_post_url(@post)
    assert_response :success
  end

  test "should update post" do
    patch post_url(@post), params: { post: { body: @post.body, title: @post.title } }
    assert_redirected_to post_url(@post)
  end

  test "should destroy post" do
    assert_difference("Post.count", -1) do
      delete post_url(@post)
    end

    assert_redirected_to posts_url
  end

  test "should delete cover image and enqueue cover regeneration job" do
    @post.cover_image.attach(
      io: StringIO.new("fake-image-bytes"),
      filename: "test.png",
      content_type: "image/png"
    )
    assert @post.cover_image.attached?

    assert_enqueued_with(job: GenerateCoverImageJob, args: [@post.id]) do
      delete purge_cover_image_post_url(@post)
    end

    assert_redirected_to post_url(@post)
    assert_equal "Cover image deleted. Regenerating new cover...", flash[:notice]
    @post.reload
    assert_not @post.cover_image.attached?
  end

  test "should delete cover image via turbo stream" do
    @post.cover_image.attach(
      io: StringIO.new("fake-image-bytes"),
      filename: "test.png",
      content_type: "image/png"
    )
    assert @post.cover_image.attached?

    assert_enqueued_with(job: GenerateCoverImageJob, args: [@post.id]) do
      delete purge_cover_image_post_url(@post), as: :turbo_stream
    end

    assert_response :success
    @post.reload
    assert_not @post.cover_image.attached?
  end
end

