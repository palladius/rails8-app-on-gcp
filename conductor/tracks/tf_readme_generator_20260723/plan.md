# Implementation Plan: Terraform Markdown Generator & Article Updater

## Phase 1: Terraform Markdown Template Generation [checkpoint: 9a418af]
- [x] Task: Write Tests (Red Phase) [466fb4d]
    - [x] Create a dummy Terraform output or locals block to verify `local_file` creation (mocking real resources for now if they don't exist).
- [x] Task: Implement to Pass Tests (Green Phase) [466fb4d]
    - [x] Create `iac/README.md.tftpl` containing the markdown structure and placeholders for Terraform outputs (GCS buckets, Secret Manager, etc.) with correct Google Cloud Console URLs.
    - [x] Add a `local_file` resource in `iac/main.tf` (or equivalent file) to render `README.md.tftpl` to `iac/TF_README.md` passing the required output variables.
- [x] Task: Conductor - User Manual Verification 'Phase 1: Terraform Markdown Template Generation' (Protocol in workflow.md)

## Phase 2: CLI Uploader Updates (Sticky Post & Comments) [checkpoint: 5bf3029]
- [x] Task: Write Tests (Red Phase) [86abf8e]
    - [x] Add test for `bin/new_article.rb` to assert that when a post with the given title already exists, it is updated rather than creating a duplicate.
    - [x] Add test to verify that a `Comment` is created on the existing post when it is updated.
- [x] Task: Implement to Pass Tests (Green Phase) [86abf8e]
    - [x] Modify `bin/new_article.rb` to search for `Post.find_by(title: parsed_title)`.
    - [x] If found, call `post.update!(body: parsed_body)` instead of `Post.create!`.
    - [x] If found and updated, execute `post.comments.create!(content: "Updated by CLI on #{Time.current}")` (or similar logging message).
- [x] Task: Conductor - User Manual Verification 'Phase 2: CLI Uploader Updates (Sticky Post & Comments)' (Protocol in workflow.md)
