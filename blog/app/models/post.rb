class Post < ApplicationRecord
  has_rich_text :body
  has_one_attached :cover_image
  has_one_attached :podcast_audio_it
  has_many :comments, dependent: :destroy
  belongs_to :user, optional: true

  # Semantic search (lib/semantic_search.rb): Gemini embedding in a pgvector column.
  has_neighbors :embedding

  after_commit :generate_cover_image_if_missing, on: [ :create, :update ]
  after_commit :generate_podcast_audio, on: [ :create, :update ]
  after_commit :refresh_embedding, on: [ :create, :update ]

  # True on PostgreSQL once the AddEmbeddingToPosts migration created the vector column.
  def self.semantic_search_ready?
    connection.adapter_name.match?(/postg/i) && column_names.include?("embedding")
  rescue ActiveRecord::ActiveRecordError
    false
  end

  private

  def refresh_embedding
    EmbedPostJob.perform_later(id) if self.class.semantic_search_ready?
  end

  def generate_cover_image_if_missing
    # Nano Banana auto-cover (issue #18): enqueue the generator when no cover is
    # attached yet. The job re-checks, so the extra enqueue on later updates is
    # harmless and the attach performed by the job itself does not loop.
    GenerateCoverImageJob.perform_later(id) unless cover_image.attached?
  end

  def generate_podcast_audio
    # Enqueue Podcastifier to generate the localized TTS if it hasn't been created
    PodcastifierJob.perform_later(id) unless podcast_audio_it.attached?
  end
end
