# Implementation Plan: Terraform Markdown Generator & Article Updater

## Phase 1: Terraform Markdown Template Generation
- [ ] Task: Write Tests (Red Phase)
    - [ ] Create a dummy Terraform output or locals block to verify `local_file` creation (mocking real resources for now if they don't exist).
- [ ] Task: Implement to Pass Tests (Green Phase)
    - [ ] Create `iac/README.md.tftpl` containing the markdown structure and placeholders for Terraform outputs (GCS buckets, Secret Manager, etc.) with correct Google Cloud Console URLs.
    - [ ] Add a `local_file` resource in `iac/main.tf` (or equivalent file) to render `README.md.tftpl` to `iac/TF_README.md` passing the required output variables.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Terraform Markdown Template Generation' (Protocol in workflow.md)

## Phase 2: CLI Uploader Updates (Sticky Post & Comments)
- [ ] Task: Write Tests (Red Phase)
    - [ ] Add test for `bin/new_article.rb` to assert that when a post with the given title already exists, it is updated rather than creating a duplicate.
    - [ ] Add test to verify that a `Comment` is created on the existing post when it is updated.
- [ ] Task: Implement to Pass Tests (Green Phase)
    - [ ] Modify `bin/new_article.rb` to search for `Post.find_by(title: parsed_title)`.
    - [ ] If found, call `post.update!(body: parsed_body)` instead of `Post.create!`.
    - [ ] If found and updated, execute `post.comments.create!(body: "Updated by CLI on #{Time.current}")` (or similar logging message).
- [ ] Task: Conductor - User Manual Verification 'Phase 2: CLI Uploader Updates (Sticky Post & Comments)' (Protocol in workflow.md)
