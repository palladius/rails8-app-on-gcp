# Implementation Plan: Simplify Post Images

## Phase 1: Model and Controller Simplification [checkpoint: 12d03a6]
- [x] Task: Write Tests (Red Phase) [12d03a6]
    - [x] Update or create tests for `PostsController` to verify that `local_image` is no longer permitted or used.
    - [x] Ensure model tests for `Post` no longer expect `local_image` to be a valid attachment.
- [x] Task: Implement to Pass Tests (Green Phase) [12d03a6]
    - [x] Remove `has_one_attached :local_image` from `app/models/post.rb`.
    - [x] Remove `:local_image` from the permitted parameters in `app/controllers/posts_controller.rb`.
- [x] Task: Conductor - User Manual Verification 'Phase 1: Model and Controller Simplification' (Protocol in workflow.md)

## Phase 2: View and UI Cleanup [checkpoint: 12d03a6]
- [x] Task: Write Tests (Red Phase) [12d03a6]
    - [x] Update system/integration tests to verify the UI only shows and interacts with `cover_image`.
- [x] Task: Implement to Pass Tests (Green Phase) [12d03a6]
    - [x] Remove the file field for `local_image` from `app/views/posts/_form.html.erb`.
    - [x] Remove `local_image` display and logic from `app/views/posts/index.html.erb` (including any image counts).
    - [x] Remove `local_image` display from `app/views/posts/show.html.erb` (if present).
    - [x] Remove `local_image` display from `app/views/posts/_post.html.erb`.
- [x] Task: Conductor - User Manual Verification 'Phase 2: View and UI Cleanup' (Protocol in workflow.md)

## Phase 3: Data Migration and Seeds [checkpoint: 12d03a6]
- [x] Task: Implement Data Migration / Seed Updates [12d03a6]
    - [x] Update `db/seeds.rb` to use `cover_image` instead of `local_image` for the local post.
- [x] Task: Conductor - User Manual Verification 'Phase 3: Data Migration and Seeds' (Protocol in workflow.md)
