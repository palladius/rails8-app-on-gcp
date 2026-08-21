# Step 7: AI Features and Background Jobs

![NanoBanana Mascot](assets/images/nano_banana_mascot.jpg)

Rails 8 introduced **Solid Queue**, a powerful database-backed job queue. We are going to use it to power a magical AI feature: **The "NanoBanana" Auto-Cover Generator**.

1. Checkout our final branch:
   ```bash
   git checkout workshop_7_ai_features
   ```

### The Architecture
Instead of making the user wait while we call the Gemini API, we offload the work to a background job. In a Cloud Run environment, this means we deploy the *same* container twice:
- **Service A (Web):** Listens for HTTP traffic.
- **Service B (Worker):** Runs `bundle exec rails solid_queue:start` and processes background jobs.

### The AI Magic
When you publish a post without a cover image, our `GenerateCoverImageJob` is triggered. 
1. It sends your article text to the Gemini/Imagen model using this prompt:
> *"Create a cover image for a blog post titled [Title]. The article contains the following text: [Text]. CRITICAL STYLE INSTRUCTION: The image MUST be rendered in the style of a 'Locandina di un film 1960' (a vintage 1960s Italian movie poster). Maintain a beautiful, cohesive vintage Italian cinematic aesthetic. Also, you MUST feature a banana somewhere in the scene."*
2. The job downloads the generated image and attaches it to the post via ActiveStorage.

Try it out! Create a new post, leave the image blank, and watch as an AI-generated, perfectly themed cover image appears a few seconds later.

