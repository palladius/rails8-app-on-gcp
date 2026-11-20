# frozen_string_literal: true

# Generates an Italian audio overview for each Post via Vertex AI translation
# and Google Cloud Text-to-Speech (ADC only). See lib/podcast_translation_service.rb.
class PodcastifierJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound

  def perform(post_id)
    post = Post.find(post_id)
    return if post.podcast_audio_it.attached?

    safe_title = PodcastTranslationService.sanitize_log(post.title, 80)
    Rails.logger.info "🎧 Podcastifier: Generating Italian TTS podcast for Post #{post.id} ('#{safe_title}')..."

    script_text = PodcastTranslationService.translate_and_summarize(
      title: post.title,
      body: post.body.to_plain_text
    )

    audio_io = CloudTtsService.synthesize(
      text: script_text,
      language_code: "it-IT",
      voice: "it-IT-Wavenet-A"
    )

    post.podcast_audio_it.attach(
      io: audio_io,
      filename: "podcast_it_#{post.id}.mp3",
      content_type: "audio/mpeg"
    )

    Turbo::StreamsChannel.broadcast_refresh_to(post) rescue nil
    Rails.logger.info "🎙️ Podcastifier: Audio attached to Post #{post.id} successfully!"
  end
end
