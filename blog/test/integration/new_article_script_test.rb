require "test_helper"
require "open3"

class NewArticleScriptTest < ActiveSupport::TestCase
  setup do
    @script_path = Rails.root.join("bin", "new_article.rb")
    @dummy_md = Rails.root.join("tmp", "dummy_article.md")
    File.write(@dummy_md, "# My Dummy Title\n\nDummy body.")
  end

  teardown do
    File.delete(@dummy_md) if File.exist?(@dummy_md)
  end

  test "creates a new post and then updates it (sticky post)" do
    assert_difference("Post.count", 1) do
      ARGV.replace(["--article", @dummy_md.to_s])
      load @script_path.to_s
    end

    post = Post.last
    assert_equal "My Dummy Title", post.title
    assert_match "Dummy body.", post.body.to_s

    # Run it again, should NOT create a new post, but should add a comment
    File.write(@dummy_md, "# My Dummy Title\n\nUpdated body.")

    assert_no_difference("Post.count") do
      assert_difference("post.comments.count", 1) do
        ARGV.replace(["--article", @dummy_md.to_s])
        load @script_path.to_s
      end
    end

    post.reload
    assert_match "Updated body.", post.body.to_s
    assert_match "Automatically updated via CLI", post.comments.last.content.to_s
  end

  test "raises error if article file doesn't exist" do
    ARGV.replace(["--article", "does_not_exist.md"])
    
    assert_raise(SystemExit) do
      load @script_path.to_s
    end
  end
end
