require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  # Post visibility regression tests
  test "unauthenticated visitor can comment on public post and user_id nil seeded post" do
    public_post = Post.create!(title: "Public Post", body: "Open", user: users(:one), public: true)
    seeded_post = Post.create!(title: "Seeded Post", body: "Workshop", user: nil, public: true)

    assert_difference("Comment.count", 1) do
      post post_comments_url(public_post), params: { comment: { commenter_name: "Guest", content: "Nice!" } }
    end
    assert_redirected_to post_url(public_post)

    assert_difference("Comment.count", 1) do
      post post_comments_url(seeded_post), params: { comment: { commenter_name: "Guest", content: "Seed comment!" } }
    end
    assert_redirected_to post_url(seeded_post)
  end

  test "unauthenticated visitor cannot comment on private post" do
    private_post = Post.create!(title: "Private Post", body: "Hidden", user: users(:one), public: false)

    assert_no_difference("Comment.count") do
      post post_comments_url(private_post), params: { comment: { commenter_name: "Attacker", content: "Leaked?" } }
    end
    assert_response :not_found
  end

  test "other authenticated user cannot comment on another user's private post" do
    private_post = Post.create!(title: "Private Post", body: "Hidden", user: users(:one), public: false)
    sign_in_as(users(:two))

    assert_no_difference("Comment.count") do
      post post_comments_url(private_post), params: { comment: { content: "Sneaky comment" } }
    end
    assert_response :not_found
  end

  test "owner can comment on own private post" do
    private_post = Post.create!(title: "Private Post", body: "Hidden", user: users(:one), public: false)
    sign_in_as(users(:one))

    assert_difference("Comment.count", 1) do
      post post_comments_url(private_post), params: { comment: { content: "Owner note" } }
    end
    assert_redirected_to post_url(private_post)
  end
end
