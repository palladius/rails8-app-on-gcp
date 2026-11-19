# frozen_string_literal: true

# Semantic search over blog posts: pgvector + Gemini RAG.
#
# * Each post gets a 768-dimension Gemini embedding (gemini-embedding-001 on
#   Vertex AI, task type RETRIEVAL_DOCUMENT) stored in posts.embedding, a
#   pgvector column with an HNSW cosine index (see the AddEmbeddingToPosts migration).
# * A query is embedded with task type RETRIEVAL_QUERY; the neighbor gem finds
#   the nearest posts by cosine distance.
# * Gemini then answers the question from those posts only, citing them as [1], [2], ...
#
# Like Nanobanana, this must never crash without cloud credentials (Constitution §6):
# on SQLite, without the vector extension, or when Vertex AI fails, it falls back to a
# plain keyword search and says so.
module SemanticSearch
  EMBEDDING_MODEL = ENV.fetch("EMBEDDING_MODEL", "gemini-embedding-001")
  CHAT_MODEL      = ENV.fetch("RAG_CHAT_MODEL", "gemini-3-flash-preview")
  DIMENSIONS      = 768
  MAX_INPUT_CHARS = 8000
  MAX_QUERY_CHARS = 500
  CONTEXT_CHARS   = 1500
  DEFAULT_LIMIT   = 5

  # mode: :semantic (pgvector + Gemini), :keyword (fallback), :empty (no query)
  Result = Data.define(:posts, :answer, :mode, :notice)

  INSTRUCTIONS = <<~TEXT
    You answer questions about a blog. Use only the numbered posts given as context.
    Cite the posts you use as [1], [2], ... Keep it short: at most five sentences.
    If the posts do not answer the question, say so plainly instead of guessing.
    Answer in the language of the question.
  TEXT

  module_function

  def search(query, scope:, limit: DEFAULT_LIMIT)
    query = query.to_s.strip[0, MAX_QUERY_CHARS]
    return Result.new(posts: [], answer: nil, mode: :empty, notice: nil) if query.blank?

    unless Post.semantic_search_ready?
      return keyword_result(query, scope, limit, "Semantic search needs PostgreSQL with pgvector; showing keyword matches.")
    end

    vector = embed(query, task: "RETRIEVAL_QUERY")
    posts  = scope.where.not(embedding: nil)
                  .nearest_neighbors(:embedding, vector, distance: "cosine")
                  .first(limit)
    Result.new(posts: posts, answer: answer(query, posts), mode: :semantic, notice: nil)
  rescue StandardError => e
    Rails.logger.warn("🔎 SemanticSearch: falling back to keyword search (#{e.class}: #{e.message})")
    keyword_result(query, scope, limit, "Gemini is not reachable right now; showing keyword matches.")
  end

  def embed(text, task:)
    RubyLLM.embed(
      text.to_s[0, MAX_INPUT_CHARS].presence || " ",
      model: EMBEDDING_MODEL, provider: :vertexai, assume_model_exists: true,
      dimensions: DIMENSIONS, task_type: task
    ).vectors
  end

  def document_text(post)
    [ post.title, post.body&.to_plain_text ].compact_blank.join("\n\n")
  end

  # Embeds one post without touching updated_at or re-running its commit callbacks.
  def embed_post!(post)
    post.update_columns(embedding: embed(document_text(post), task: "RETRIEVAL_DOCUMENT"))
  end

  def answer(query, posts)
    return nil if posts.empty?

    RubyLLM.chat(model: CHAT_MODEL, provider: :vertexai, assume_model_exists: true)
           .with_instructions(INSTRUCTIONS)
           .ask(prompt_for(query, posts))
           .content.to_s.strip.presence
  end

  def prompt_for(query, posts)
    context = posts.each_with_index.map do |post, i|
      "[#{i + 1}] #{post.title}\n#{post.body&.to_plain_text.to_s[0, CONTEXT_CHARS]}"
    end
    "Posts:\n\n#{context.join("\n\n")}\n\nQuestion: #{query}"
  end

  def keyword_result(query, scope, limit, notice)
    Result.new(posts: keyword_search(query, scope, limit), answer: nil, mode: :keyword, notice: notice)
  end

  def keyword_search(query, scope, limit)
    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query.downcase)}%"
    scope.left_joins(:rich_text_body)
         .where("LOWER(posts.title) LIKE :q OR LOWER(action_text_rich_texts.body) LIKE :q", q: pattern)
         .distinct.order(created_at: :desc).limit(limit).to_a
  end
end
