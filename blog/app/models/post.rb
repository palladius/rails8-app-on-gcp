class Post < ApplicationRecord
  has_rich_text :body
  has_one_attached :cover_image
  has_one_attached :local_image, service: :local
  has_one_attached :podcast_audio_it
  has_many :comments, dependent: :destroy

  after_commit :generate_cover_image_if_missing, on: [:create, :update]
  after_commit :generate_podcast_audio, on: [:create, :update]

  private

  def generate_cover_image_if_missing
    # We enqueue the NanoBanana generator job if there's no cover image attached yet.
    GenerateCoverImageJob.perform_later(id) unless cover_image.attached?
  end

  def generate_podcast_audio
    # Enqueue Podcastifier to generate the localized TTS if it hasn't been created
    PodcastifierJob.perform_later(id) unless podcast_audio_it.attached?
  end
end
