# Conductor Implementation Plan: Nano Banana Auto-Cover Generation

> **Track ID:** `nanobanana_cover_issue_18_20260908`  
> **Status:** Done (pending `terraform apply` on the workshop project)  

---

### Task 1: Generator module `blog/lib/nanobanana.rb`
- [x] `unintelligible_or_too_short?` (< 30 bytes, keyboard mash) and `prompt_for` (poster style, banana, ruby "8", Prog Metal in Modena fallback).
- [x] `available?` / `generate_image` on Vertex AI (`gemini-2.5-flash-image`, `generateContent`, `responseModalities: IMAGE`) with ADC bearer token via `googleauth`, Net::HTTP timeouts.
- [x] Fake cover fallback `app/assets/images/nanobanana_fake_cover.png` on every failure path.
- [x] `storage_tier` + `stamp_provenance` with libvips (grayscale + house stamp locally, cloud stamp on GCS).

### Task 2: Job, model, CLI
- [x] Rewrite `GenerateCoverImageJob` (fix `post.content` → `post.body.to_plain_text`, attach stamped PNG, `broadcast_refresh_to`).
- [x] `bin/new_article.rb` attaches `--image` before `save!` so no generation job is enqueued.

### Task 3: UI provenance
- [x] `ApplicationHelper#storage_tier`, `#cover_image_classes`, `#cover_image_title`; footer badge reuses `storage_tier`.
- [x] `.cover-image--local { filter: grayscale(1) }` on show / index / `_post` cover images.

### Task 4: Tests (offline, < 5 s)
- [x] `config/environments/test.rb` → Disk storage service (`ACTIVE_STORAGE_SERVICE` override).
- [x] `test/test_helpers/stub_helper.rb` (`stub_singleton`, minitest 6 has no `minitest/mock`).
- [x] `test/lib/nanobanana_test.rb`, `test/jobs/generate_cover_image_job_test.rb`, `test/models/post_test.rb`, helper tests.

### Task 5: Infrastructure
- [x] `iac/cloudrun.tf`: `google_project_service.aiplatform`, `roles/aiplatform.user` on the Cloud Run SA and on `var.developers`.
- [ ] `cd iac && terraform apply` on the workshop project (manual).

### Task 6: Docs
- [x] `workshop/SKELETON.md`, `CODELAB.md`, `UNTOUCHABLE-CONSTITUTION.md` (Vertex AI + ADC, fallback, stamps).
- [x] `CHANGELOG.md` 0.1.26, `VERSION`, conductor registry.
