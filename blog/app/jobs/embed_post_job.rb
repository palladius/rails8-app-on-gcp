# Semantic search: stores the Gemini embedding of a post (or of every post still
# missing one, when called without an id). See lib/semantic_search.rb.
class EmbedPostJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound

  def perform(post_id = nil)
    return unless Post.semantic_search_ready?

    posts = post_id ? [ Post.find(post_id) ] : Post.where(embedding: nil).limit(200)
    posts.each { |post| SemanticSearch.embed_post!(post) }
  end
end
