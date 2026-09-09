class PodcastifierJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    # TODO(student): COMPLETE_ME — Pair program with Google Antigravity to implement
    # Italian TTS podcast generation using voice 'it-IT-Wavenet-A' via Cloud TTS / ADC!
  end
end
