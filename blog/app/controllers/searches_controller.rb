# Semantic search over posts: pgvector nearest neighbours + a Gemini answer (RAG).
# See lib/semantic_search.rb.
class SearchesController < ApplicationController
  allow_unauthenticated_access
  # Every query costs a Vertex AI embedding and a Gemini call.
  rate_limit to: 20, within: 1.minute, only: :show, with: -> { redirect_to search_path, alert: "Too many searches. Try again in a minute." }

  def show
    @query  = params[:q].to_s.strip
    @result = SemanticSearch.search(@query, scope: visible_posts) if @query.present?
    backfill_embeddings
  end

  private

  # Same visibility rule as PostsController#index.
  def visible_posts
    Post.where(user: Current.user).or(Post.where(public: true)).or(Post.where(user_id: nil))
  end

  # Posts written before the vector column existed get embedded in the background,
  # at most once every ten minutes.
  def backfill_embeddings
    return unless Post.semantic_search_ready? && Post.where(embedding: nil).exists?

    Rails.cache.fetch("semantic_search/backfill", expires_in: 10.minutes) do
      EmbedPostJob.perform_later
      true
    end
  end
end
