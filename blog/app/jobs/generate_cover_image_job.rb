# Nano Banana auto-cover (issue #18): a Post saved without a cover image gets a
# vintage Italian movie poster generated on Vertex AI, or an honest fake cover
# when credentials are missing. See lib/nanobanana.rb for the details.
class GenerateCoverImageJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound

  def perform(post_id)
    post = Post.find(post_id)
    return if post.cover_image.attached? # title + body + image → nothing to do

    Rails.logger.info "🍌 Nano Banana: generating cover image for Post #{post.id}..."

    prompt = Nanobanana.prompt_for(post.title, post.body.to_plain_text)
    result = Nanobanana.generate_image(prompt)
    tier   = Nanobanana.storage_tier
    png    = Nanobanana.stamp_provenance(result.data, tier: tier)

    post.cover_image.attach(
      io: StringIO.new(png),
      filename: "cover_#{post.id}_#{result.source}_#{tier}.png",
      content_type: "image/png"
    )

    # posts/show.html.erb subscribes with `turbo_stream_from @post`: whoever is
    # looking at the post sees the cover appear without reloading.
    Turbo::StreamsChannel.broadcast_refresh_to(post)

    Rails.logger.info "🎨 Nano Banana: cover attached to Post #{post.id} (#{result.source}, #{tier})"
  end
end
