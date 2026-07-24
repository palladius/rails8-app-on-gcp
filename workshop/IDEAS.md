## Workshop ideas

* [Emiliano] At the beginning, ask user to add user and password to seeds for login.
* [Riccardo] At beginning ask Gemini to TAL at models and make an E/R diagram using mermaid and embed/render in README.md (or a new ARCHITECTURE.md)
* [Riccardo] Explain ActiveStorage image handling across environments: have a v1 branch where images are saved locally, and a v2 branch where images are migrated/configured for remote GCS.
* [Riccardo] Deployment Alternatives: As an exercise, launch the app using Kamal on a single GCE instance.
* [Riccardo] Deployment Alternatives: Launch as a single tri-docker via `docker-compose` on a GCE VM with a container-optimized OS (COS).

## Background Jobs & Solid Queue Brainstorming (The "Worker" Story)

In a Blog app context, the background worker (Solid Queue) is perfect for tasks that take too long for a standard HTTP request. Here are some ideas for the workshop:

1. **The "NanoBanana" Auto-Cover Generator (AI)** 🍌
   - **Trigger:** A user publishes a post without uploading a cover image.
   - **Job:** A Solid Queue worker sends the article's text to an image generation model (Imagen/Gemini) to generate a custom, contextual cover image. We append a consistent styling prompt to all requests—specifically *"in the style of a 'Locandina di un film 1960' (vintage 1960s Italian movie poster), and must feature a banana somewhere"*—so the entire blog has a beautiful, cohesive look and feel. It then downloads the result and automatically attaches it to the post via ActiveStorage.
   - **Why it's great:** Teaches ActiveStorage attachment from a URL/background process + AI Image generation with prompt engineering for brand consistency.

2. **SEO & Metadata Assistant (AI)** 📝
   - **Trigger:** A post is saved or updated.
   - **Job:** Gemini reads the content and automatically generates a 2-sentence SEO summary/excerpt, extracts 3-5 relevant tags, and calculates a clickability score.
   - **Why it's great:** A classic CMS use-case that shows how AI can enhance standard CRUD apps without being gimmicky.

3. **Deterministic Content Metrics (Non-AI)** 📊
   - **Trigger:** If an article crosses a certain threshold (e.g., > 50 words).
   - **Job:** A deterministic worker calculates Exact Word Count, Estimated Reading Time (based on 200 WPM), and Fog Index (readability score). 
   - **Why it's great:** Good contrast to AI. Shows students that Solid Queue is also for heavy deterministic calculations or metric aggregations (like triggering MCP tools to check for broken links in the article).

4. **The "Podcastifier" (Multi-language Text-to-Speech)** 🎧
   - **Trigger:** An article is finalized.
   - **Job:** The worker first uses Cloud Translation (or Gemini) to translate the article into multiple languages (e.g., shipping v1 with English and Italian). Then it calls the Google Cloud Text-to-Speech API to generate a `.mp3` for each language (ensuring the Italian TTS engine reads the Italian translation so words like "dove" are pronounced correctly). It attaches these `.mp3` files to the post so users can listen on the go in their preferred language.

## App notes

* Let's ensure we prevent bad Data currptuion, like db:seed populating the same post more than once, at the cost of addinhg stupid primary keys, eg Post `title` uniqueness.
