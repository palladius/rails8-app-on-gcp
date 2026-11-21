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

  # Post visibility and ownership regression tests
  test "unauthenticated user cannot view another user's private post" do
    private_post = Post.create!(title: "Secret Note", body: "Private content", user: users(:one), public: false)
    sign_out

    get post_url(private_post)
    assert_response :not_found
  end

  test "other authenticated user cannot view another user's private post" do
    private_post = Post.create!(title: "Secret Note", body: "Private content", user: users(:one), public: false)
    sign_in_as(users(:two))

    get post_url(private_post)
    assert_response :not_found
  end

  test "owner can view own private post on show and index (session resumed on public actions)" do
    private_post = Post.create!(title: "Owner Private Note", body: "Only for me", user: users(:one), public: false)

    get post_url(private_post)
    assert_response :success

    get posts_url
    assert_response :success
    assert_includes response.body, "Owner Private Note"
  end

  test "other authenticated user gets 403 and cannot edit, update, destroy, or purge cover of user one's public post" do
    owners_post = Post.create!(title: "Owner Public", body: "Original body", user: users(:one), public: true)
    owners_post.cover_image.attach(
      io: StringIO.new("\x89PNG\r\n\x1a\n"),
      filename: "owner.png",
      content_type: "image/png"
    )
    sign_in_as(users(:two))

    get edit_post_url(owners_post)
    assert_response :forbidden

    patch post_url(owners_post), params: { post: { title: "Hacked Title", body: "Hacked body" } }
    assert_response :forbidden
    assert_equal "Owner Public", owners_post.reload.title

    assert_no_difference("Post.count") do
      delete post_url(owners_post)
    end
    assert_response :forbidden

    assert_no_enqueued_jobs(only: GenerateCoverImageJob) do
      delete purge_cover_image_post_url(owners_post)
    end
    assert_response :forbidden
    assert owners_post.reload.cover_image.attached?

    assert_no_enqueued_jobs(only: GenerateCoverImageJob) do
      delete purge_cover_image_post_url(owners_post), as: :turbo_stream
    end
    assert_response :forbidden
    assert owners_post.reload.cover_image.attached?
  end

  test "other authenticated user gets 404 when trying to edit, update, destroy, or purge private post" do
    private_post = Post.create!(title: "Owner Private", body: "Hidden", user: users(:one), public: false)
    sign_in_as(users(:two))

    get edit_post_url(private_post)
    assert_response :not_found

    patch post_url(private_post), params: { post: { title: "Hacked" } }
    assert_response :not_found
    assert_equal "Owner Private", private_post.reload.title

    assert_no_difference("Post.count") do
      delete post_url(private_post)
    end
    assert_response :not_found

    delete purge_cover_image_post_url(private_post)
    assert_response :not_found
  end

  test "unauthenticated user can view user_id nil seeded posts and authenticated users can modify them" do
    seeded_public = Post.create!(title: "Seeded Public", body: "Workshop", user: nil, public: true)
    seeded_private = Post.create!(title: "Seeded Private", body: "Workshop", user: nil, public: false)
    seeded_public.cover_image.attach(
      io: StringIO.new("\x89PNG\r\n\x1a\n"),
      filename: "seed.png",
      content_type: "image/png"
    )

    sign_out
    get post_url(seeded_public)
    assert_response :success
    get post_url(seeded_private)
    assert_response :success

    sign_in_as(users(:two))
    get edit_post_url(seeded_public)
    assert_response :success

    patch post_url(seeded_public), params: { post: { title: "Updated Seeded" } }
    assert_redirected_to post_url(seeded_public)
    assert_equal "Updated Seeded", seeded_public.reload.title

    assert_enqueued_with(job: GenerateCoverImageJob, args: [seeded_public.id]) do
      delete purge_cover_image_post_url(seeded_public)
    end
    assert_redirected_to post_url(seeded_public)
    assert_not seeded_public.reload.cover_image.attached?

    assert_difference("Post.count", -1) do
      delete post_url(seeded_public)
    end
    assert_redirected_to posts_url
  end
end

