require "test_helper"

# Semantic search must never need the network in tests (Localhost invariant):
# SQLite has no pgvector, so search falls back to keywords; Gemini calls are stubbed.
class SemanticSearchTest < ActiveSupport::TestCase
  test "blank query returns an empty result without searching" do
    result = SemanticSearch.search("   ", scope: Post.all)

    assert_equal :empty, result.mode
    assert_empty result.posts
    assert_nil result.answer
  end

  test "SQLite is not ready for semantic search" do
    assert_not Post.semantic_search_ready?
  end

  test "without pgvector it falls back to case-insensitive keyword search and says so" do
    result = SemanticSearch.search("SECOND test", scope: Post.all)

    assert_equal :keyword, result.mode
    assert_equal [ posts(:two) ], result.posts
    assert_match(/pgvector/, result.notice)
    assert_nil result.answer
  end

  test "keyword fallback also matches the rich text body" do
    post = Post.create!(title: "Summer in Sicily", body: "<p>Pistachio gelato from Bronte</p>")

    result = SemanticSearch.search("PISTACHIO", scope: Post.all)

    assert_equal [ post ], result.posts
  end

  test "a Vertex AI failure falls back to keyword search instead of raising" do
    stub_singleton(Post, :semantic_search_ready?, true) do
      stub_singleton(SemanticSearch, :embed, ->(*, **) { raise RubyLLM::Error, "no credentials" }) do
        result = SemanticSearch.search("first", scope: Post.all)

        assert_equal :keyword, result.mode
        assert_match(/Gemini/, result.notice)
        assert_includes result.posts, posts(:one)
      end
    end
  end

  test "the RAG prompt numbers the posts so the answer can cite them" do
    prompt = SemanticSearch.prompt_for("What is first?", [ posts(:one), posts(:two) ])

    assert_match(/\[1\] My First Test Post/, prompt)
    assert_match(/\[2\] My Second Test Post/, prompt)
    assert_match(/Question: What is first\?/, prompt)
  end

  test "no posts means no Gemini answer" do
    assert_nil SemanticSearch.answer("anything", [])
  end

  test "document text combines title and plain-text body" do
    post = Post.create!(title: "Summer in Sicily", body: "<p>Pistachio <strong>gelato</strong></p>")

    assert_equal "Summer in Sicily\n\nPistachio gelato", SemanticSearch.document_text(post)
  end
end
