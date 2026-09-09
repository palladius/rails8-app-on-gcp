# Conductor Track Specification: Delete and Refresh Article Cover Image

> **Track ID:** `delete_cover_image_issue_34_20260909`  
> **Type:** Feature  
> **Related Issue:** [#34](https://github.com/palladius/rails8-app-on-gcp/issues/34) (Follow-up to [#18](https://github.com/palladius/rails8-app-on-gcp/issues/18))  

---

## 🎯 Overview & Strategic Value
With the Nano Banana cover generation introduced in Issue #18, posts automatically receive an AI-generated or fallback cover image. Sometimes users or workshop attendees receive a fallback/fake cover or wish to re-roll their AI image.
Currently, there is no direct UI mechanism to delete an existing cover image or trigger a regeneration without manually editing or modifying the database.

This feature introduces a clean, accessible action to delete/purge an article's cover image. In alignment with Issue #34, deleting the cover immediately kicks off the same background cover generation job (`GenerateCoverImageJob`), giving users a seamless "delete and refresh" workflow with live UI updates via Turbo Streams.

---

## 📋 Functional Requirements

1. **Routing & Action:**
   - Add a custom route on `resources :posts` (e.g. `delete :cover_image, on: :member` or `purge_cover_image`).
   - The action purges the `cover_image` attachment (`@post.cover_image.purge_later` or `purge`).
   - Immediately enqueues `GenerateCoverImageJob.perform_later(@post.id)`.
   - Supports both Turbo Stream response (refreshing the post or broadcasting refresh) and standard HTML redirect back to `@post` or `edit_post_path(@post)` with an informative flash notice.

2. **UI Integration:**
   - **Show View (`posts/show.html.erb`):** Place a button (e.g. "🔄 Regenerate Cover" / "🗑️ Delete & Refresh Image") in the hero glass section or post actions bar when a cover image is attached.
   - **Edit View (`posts/_form.html.erb` or `posts/edit.html.erb`):** Display the current image preview with a direct button to remove & regenerate the cover image.

3. **Authorization & Security:**
   - Ensure the action is protected similarly to `edit`/`update`/`destroy` (authenticated user check: only the post owner or unauthenticated if the post has no author).

4. **Turbo Broadcast & Reactive UI:**
   - Since `GenerateCoverImageJob` already executes `Turbo::StreamsChannel.broadcast_refresh_to(post)`, purging the image and triggering the job ensures that viewers on `posts/show` see the old image vanish and the new one asynchronously appear.

5. **Testing & Diagnostics:**
   - Model/Controller tests for the delete & regenerate endpoint.
   - Verify that purging enqueues `GenerateCoverImageJob` and broadcasts updates.
   - Offline test suite execution under 5 seconds in accordance with repo standards.

---

## 🚫 Out of Scope
- Separate multi-action modal (e.g. choosing between permanent removal vs regeneration) — issue specifies deleting should trigger regeneration.
- Modifying `PodcastifierJob` or podcast audio attachments.
