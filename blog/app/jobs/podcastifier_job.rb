# frozen_string_literal: true

class PodcastifierJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound

  def perform(post_id)
    post = Post.find(post_id)
    return if post.podcast_audio_it.attached?

    Rails.logger.info "🎧 Podcastifier: Generating Italian TTS podcast for Post #{post.id} ('#{post.title}')..."

    # Simple Italian summary script for the podcast
    title = post.title.presence || "Articolo"
    body_text = post.body.to_plain_text.presence || ""
    summary_text = "Benvenuti al podcast del blog! Oggi parliamo di: #{title}. #{body_text.truncate(250)}"

    audio_io = CloudTtsService.synthesize(text: summary_text, language_code: "it-IT", voice: "it-IT-Wavenet-A")

    post.podcast_audio_it.attach(
      io: audio_io,
      filename: "podcast_it_#{post.id}.mp3",
      content_type: "audio/mpeg"
    )

    Turbo::StreamsChannel.broadcast_refresh_to(post) rescue nil
    Rails.logger.info "🎙️ Podcastifier: Audio attached to Post #{post.id} successfully!"
  end
end
