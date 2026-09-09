# Conductor Track Implementation Plan: Delete & Refresh Article Cover Image

> **Track ID:** `delete_cover_image_issue_34_20260909`  
> **Related Spec:** [spec.md](./spec.md)  

---

### Phase 1: Controller Routing & Backend Endpoint (TDD)
- [ ] Task: Add failing functional/controller tests for deleting cover image and triggering regeneration
    - [ ] Add tests in `test/controllers/posts_controller_test.rb` testing `DELETE /posts/:id/cover_image`
    - [ ] Assert that `post.cover_image` is purged
    - [ ] Assert that `GenerateCoverImageJob` is enqueued
    - [ ] Assert proper authorization and redirects/turbo stream handling
- [ ] Task: Implement route and controller action
    - [ ] Add member route `delete :cover_image, on: :member` in `config/routes.rb`
    - [ ] Implement `cover_image` delete action in `PostsController`
    - [ ] Run controller tests to ensure green
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

### Phase 2: Frontend Views & Turbo UI Integration
- [ ] Task: Add UI trigger in `posts/show.html.erb`
    - [ ] Add button with confirmation prompt (`data: { turbo_confirm: "Delete current image and generate a new one?" }`) in `posts/show.html.erb`
- [ ] Task: Add UI trigger in `posts/_form.html.erb` / `posts/edit.html.erb`
    - [ ] Display current cover image preview with the delete & regenerate button if an image is attached
- [ ] Task: System / Integration Verification
    - [ ] Verify Turbo Stream response or page refresh behaviour
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

### Phase 3: Final Verification & Test Suite
- [ ] Task: Run full test suite and verify fast execution
    - [ ] Run `just test` (or `bin/rails test`) ensuring tests complete in < 5 seconds
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)
