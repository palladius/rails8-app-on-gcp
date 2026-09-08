# Conductor Track Specification: Nano Banana Auto-Cover Generation

> **Track ID:** `nanobanana_cover_issue_18_20260908`  
> **Type:** Feature  
> **Related Issue:** [#18](https://github.com/palladius/rails8-app-on-gcp/issues/18) (narrative decisions in [#14](https://github.com/palladius/rails8-app-on-gcp/issues/14))  

---

## 🎯 Overview & Strategic Value
Step 7 of the workshop promises a "wow" moment: publish a post without a cover image and watch an AI-generated vintage Italian movie poster appear. Until now `GenerateCoverImageJob` was a mock that could not even run (it referenced a non-existent `post.content`).

This track makes the feature real **and pedagogical**:
1. **Nano Banana on Vertex AI** (`gemini-2.5-flash-image`) generates the poster from title + body, always with a cameo banana and a ruby gem shaped like an "8" in the top-right corner.
2. **Prog Metal in Modena** fallback prompt when the text is under 30 bytes or keyboard mash (`qwerty`, `asdf`, ...).
3. **ADC only** — the Cloud Run service account or the developer's `gcloud auth application-default login`. No AI Studio API keys (decision in #14).
4. **Localhost Invariant** (Constitution §6): without credentials/API/network the job attaches a bundled, honest *fake cover* ("Pretend I'm real!") instead of failing.
5. **Asset provenance** (Constitution §5): the cover shows where it lives — grayscale + house/`127.0.0.1` on ephemeral local disk, colorful cloud on GCS. User uploads get the same grayscale as a CSS filter while local, untouched on GCS.

---

## 📋 Functional Requirements
- `Post` saved without `cover_image` → `GenerateCoverImageJob` enqueued (already the case); with a cover → nothing happens (NOOP), including for `bin/new_article.rb --image`.
- Single module `blog/lib/nanobanana.rb` (no `app/services`, `archspec :vanilla_rails`): `prompt_for`, `unintelligible_or_too_short?`, `available?`, `generate_image`, `storage_tier`, `stamp_provenance`.
- Net::HTTP + `googleauth` ADC bearer token; `open_timeout 5s`, `read_timeout 90s`; every failure path returns the fake cover and logs one clear English line with an emoji.
- Provenance stamping with libvips (already in the Docker image), deterministic, never raises.
- Turbo Stream refresh broadcast so the poster shows up without reloading the post page.
- Terraform: enable `aiplatform.googleapis.com`, `roles/aiplatform.user` on `rails-cloudrun-sa` and on `var.developers`.
- Tests run offline in < 5 s (test env on the Disk storage service, HTTP stubbed).
- Workshop docs (SKELETON / CODELAB / UNTOUCHABLE-CONSTITUTION) describe Vertex AI + ADC, the fallback and the stamps; no `GEMINI_API_KEY` left in the curriculum.

## 🚫 Out of Scope
- `bin/workshop_diagnostics.rb` check for the Vertex AI API.
- `.env.dist` / `compose.prod.yaml` cleanup of the unused `GEMINI_API_KEY`.
- `WORKSHOP_STEP`-driven seeds and the GCS treasure hunt (#14, #23).
