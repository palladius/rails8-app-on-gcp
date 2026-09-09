# Conductor Track Implementation Plan: Delete & Refresh Article Cover Image

> **Track ID:** `delete_cover_image_issue_34_20260909`  
> **Related Spec:** [spec.md](./spec.md)  

---

### Phase 1: Controller Routing & Backend Endpoint (TDD)
- [x] Task: Add failing functional/controller tests for deleting cover image and triggering regeneration
    - [x] Add tests in `test/controllers/posts_controller_test.rb` testing `DELETE /posts/:id/cover_image`
    - [x] Assert that `post.cover_image` is purged
    - [x] Assert that `GenerateCoverImageJob` is enqueued
    - [x] Assert proper authorization and redirects/turbo stream handling
- [x] Task: Implement route and controller action
    - [x] Add member route `delete :purge_cover_image, on: :member` in `config/routes.rb`
    - [x] Implement `purge_cover_image` delete action in `PostsController`
    - [x] Run controller tests to ensure green
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md)

### Phase 2: Frontend Views & Turbo UI Integration
- [x] Task: Add UI trigger in `posts/show.html.erb`
    - [x] Add button with confirmation prompt (`data: { turbo_confirm: "Delete current cover image and generate a new one?" }`) in `posts/show.html.erb`
- [x] Task: Add UI trigger in `posts/_form.html.erb` / `posts/edit.html.erb`
    - [x] Display current cover image preview with the delete & regenerate button if an image is attached
- [x] Task: System / Integration Verification
    - [x] Verify Turbo Stream response or page refresh behaviour
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md)

### Phase 3: Final Verification & Test Suite
- [x] Task: Run full test suite and verify fast execution
    - [x] Run `just test` (or `bin/rails test`) ensuring tests complete in < 5 seconds
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md)
