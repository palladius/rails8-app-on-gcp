# Semantic search (pgvector + Gemini RAG): a 768-dimension embedding per post with an
# HNSW cosine index. Only on PostgreSQL with the pgvector extension available (Cloud SQL
# has it); SQLite and plain postgres images skip it and the app falls back to keyword search.
class AddEmbeddingToPosts < ActiveRecord::Migration[8.1]
  # CREATE EXTENSION may be refused; without a transaction a refusal does not abort the boot.
  disable_ddl_transaction!

  def up
    return unless connection.adapter_name.match?(/postg/i)
    return unless select_value("SELECT 1 FROM pg_available_extensions WHERE name = 'vector'")

    begin
      enable_extension "vector"
    rescue ActiveRecord::StatementInvalid => e
      say "pgvector extension not enabled (#{e.message.lines.first.strip}); semantic search stays off"
      return
    end

    add_column :posts, :embedding, :vector, limit: 768 unless column_exists?(:posts, :embedding)
    add_index :posts, :embedding, using: :hnsw, opclass: :vector_cosine_ops, if_not_exists: true
  end

  def down
    remove_column :posts, :embedding if column_exists?(:posts, :embedding)
  end
end
