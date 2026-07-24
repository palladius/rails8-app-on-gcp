class GenerateCoverImageJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    post = Post.find(post_id)
    return if post.cover_image.attached?

    Rails.logger.info "🍌 NanoBanana AI: Generating cover image for Post #{post.id}..."

    prompt = <<~PROMPT
      Create a cover image for a blog post titled "#{post.title}".
      The article contains the following text: "#{post.content.to_s.truncate(500)}".
      
      CRITICAL STYLE INSTRUCTION: The image MUST be rendered in the style of a "Locandina di un film 1960" (a vintage 1960s Italian movie poster). 
      Maintain a beautiful, cohesive vintage Italian cinematic aesthetic. 
      Also, you MUST feature a banana somewhere in the scene.
    PROMPT

    # Mocking the AI service call for now. In a real app, we'd use Gemini/Imagen here.
    # image_io = AiService.generate_image(prompt)
    # post.cover_image.attach(io: image_io, filename: "cover_#{post.id}.jpg")
    
    Rails.logger.info "🎨 Cover image generated with prompt: #{prompt.inspect}"
  end
end
