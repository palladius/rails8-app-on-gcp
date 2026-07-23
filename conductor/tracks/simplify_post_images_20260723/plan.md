# Implementation Plan: Simplify Post Images

## Phase 1: Model and Controller Simplification
- [ ] Task: Write Tests (Red Phase)
    - [ ] Update or create tests for `PostsController` to verify that `local_image` is no longer permitted or used.
    - [ ] Ensure model tests for `Post` no longer expect `local_image` to be a valid attachment.
- [ ] Task: Implement to Pass Tests (Green Phase)
    - [ ] Remove `has_one_attached :local_image` from `app/models/post.rb`.
    - [ ] Remove `:local_image` from the permitted parameters in `app/controllers/posts_controller.rb`.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Model and Controller Simplification' (Protocol in workflow.md)

## Phase 2: View and UI Cleanup
- [ ] Task: Write Tests (Red Phase)
    - [ ] Update system/integration tests to verify the UI only shows and interacts with `cover_image`.
- [ ] Task: Implement to Pass Tests (Green Phase)
    - [ ] Remove the file field for `local_image` from `app/views/posts/_form.html.erb`.
    - [ ] Remove `local_image` display and logic from `app/views/posts/index.html.erb` (including any image counts).
    - [ ] Remove `local_image` display from `app/views/posts/show.html.erb` (if present).
- [ ] Task: Conductor - User Manual Verification 'Phase 2: View and UI Cleanup' (Protocol in workflow.md)

## Phase 3: Data Migration and Seeds
- [ ] Task: Implement Data Migration / Seed Updates
    - [ ] Create a script, migration, or simply update `db/seeds.rb` to ensure that standard posts (and any visual feedback posts) are correctly mapped to use `cover_image` instead of `local_image`.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Data Migration and Seeds' (Protocol in workflow.md)
