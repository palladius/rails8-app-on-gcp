class Post < ApplicationRecord
  has_rich_text :body
  has_one_attached :cover_image
  has_one_attached :podcast_audio_it
  has_many :comments, dependent: :destroy
  belongs_to :user, optional: true

  after_commit :generate_cover_image_if_missing, on: [ :create, :update ]
  after_commit :generate_podcast_audio, on: [ :create, :update ]

  scope :visible_to, ->(current_user) {
    base = where(public: true).or(where(user_id: nil))
    current_user ? base.or(where(user: current_user)) : base
  }

  def visible_to?(current_user)
    public? || user_id.nil? || (current_user.present? && user_id == current_user.id)
  end

  def modifiable_by?(current_user)
    current_user.present? && (user_id.nil? || user_id == current_user.id)
  end

  private

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
