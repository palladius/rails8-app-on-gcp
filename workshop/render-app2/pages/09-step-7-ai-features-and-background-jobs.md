# Step 7: AI Features and Background Jobs

![NanoBanana Mascot](assets/images/nano_banana_mascot.jpg)

Rails 8's **Solid Queue** powers asynchronous background tasks without needing Redis. Let's use it for an AI feature: **The "NanoBanana" Auto-Cover Generator**.

1. Checkout our final branch:
   ```bash
   git checkout workshop_7_ai_features
   ```

2. When a post is saved without a cover image, `GenerateCoverImageJob` triggers:
   - It sends the post title and summary to Google's Gemini / Imagen model with this prompt:
     > *"Create a cover image for a blog post titled [Title]. The article contains the following text: [Text]. CRITICAL STYLE INSTRUCTION: The image MUST be rendered in the style of a 'Locandina di un film 1960' (a vintage 1960s Italian movie poster). Maintain a beautiful vintage Italian cinematic aesthetic. Also, you MUST feature a banana somewhere in the scene."*
   - The Solid Queue worker downloads the generated image and attaches it directly via ActiveStorage.

3. Create a new post, leave the cover image empty, and publish.

✨ **The Wow Moment:** In a few seconds, an AI-generated vintage Italian poster featuring a cameo banana appears automatically on your post, processed completely asynchronously by Solid Queue on Cloud Run!

