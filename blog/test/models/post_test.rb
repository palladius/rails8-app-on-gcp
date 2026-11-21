require "test_helper"

class PostTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "creating a post without a cover enqueues the Nano Banana job" do
    assert_enqueued_with(job: GenerateCoverImageJob) do
      Post.create!(title: "No cover here", body: "Somebody please draw me a banana.")
    end
  end

  test "creating a post with a cover attached does not enqueue the job" do
    post = Post.new(title: "Already illustrated", body: "I brought my own picture.")
    post.cover_image.attach(io: File.open(Rails.root.join("db/seeds/test_image_600x400.jpg")), filename: "mine.jpg", content_type: "image/jpeg")

    assert_no_enqueued_jobs(only: GenerateCoverImageJob) do
      post.save!
    end
  end

  # Post visibility and ownership regression tests
  test "visible_to scope and visible_to? enforce private post visibility while preserving user_id nil seeded posts" do
    owner = users(:one)
    other = users(:two)

    public_post = Post.create!(title: "Owner Public", body: "Visible", user: owner, public: true)
    private_post = Post.create!(title: "Owner Private", body: "Secret", user: owner, public: false)
    seeded_public = Post.create!(title: "Seeded Public", body: "Workshop", user: nil, public: true)
    seeded_private = Post.create!(title: "Seeded Private", body: "Workshop", user: nil, public: false)

    # Anonymous viewer
    anon_visible = Post.visible_to(nil).pluck(:id)
    assert_includes anon_visible, public_post.id
    assert_includes anon_visible, seeded_public.id
    assert_includes anon_visible, seeded_private.id
    assert_not_includes anon_visible, private_post.id

    assert public_post.visible_to?(nil)
    assert seeded_public.visible_to?(nil)
    assert seeded_private.visible_to?(nil)
    assert_not private_post.visible_to?(nil)

    # Other authenticated user
    other_visible = Post.visible_to(other).pluck(:id)
    assert_includes other_visible, public_post.id
    assert_includes other_visible, seeded_public.id
    assert_includes other_visible, seeded_private.id
    assert_not_includes other_visible, private_post.id

    assert_not private_post.visible_to?(other)

    # Post owner
    owner_visible = Post.visible_to(owner).pluck(:id)
    assert_includes owner_visible, private_post.id
    assert private_post.visible_to?(owner)
  end

  test "modifiable_by? allows owner and any authenticated user for user_id nil posts but rejects others and nil" do
    owner = users(:one)
    other = users(:two)

    owned_post = Post.create!(title: "Owned", body: "Mine", user: owner, public: true)
    seeded_post = Post.create!(title: "Seeded", body: "Workshop", user: nil, public: true)

    assert owned_post.modifiable_by?(owner)
    assert_not owned_post.modifiable_by?(other)
    assert_not owned_post.modifiable_by?(nil)

    assert seeded_post.modifiable_by?(owner)
    assert seeded_post.modifiable_by?(other)
    assert_not seeded_post.modifiable_by?(nil)
  end
end
