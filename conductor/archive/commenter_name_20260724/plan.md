# Implementation Plan

## Phase 1: Database and Model Updates
- [x] Task: Generate database migration
    - [x] Create migration to add `user_id` (references, optional) and `commenter_name` (string) to `comments` table.
    - [x] Run `bin/rails db:migrate`.
- [x] Task: Update Comment model
    - [x] Add `belongs_to :user, optional: true` to `app/models/comment.rb`.
    - [x] Implement `author_name` method with fallback logic (User's name -> `commenter_name` -> "Anonymous").
- [x] Task: Conductor - User Manual Verification 'Phase 1: Database and Model Updates' (Protocol in workflow.md)

## Phase 2: User Interface Updates
- [x] Task: Update Comment form
    - [x] Modify `app/views/comments/_form.html.erb` to include a `commenter_name` field for guests.
- [x] Task: Update Comment display
    - [x] Modify `app/views/comments/_comment.html.erb` to bold the author's name (`**<%= comment.author_name %>:**`).
- [x] Task: Conductor - User Manual Verification 'Phase 2: User Interface Updates' (Protocol in workflow.md)

## Phase 3: Seeding and Polish
- [x] Task: Update `db/seeds.rb`
    - [x] Adjust `find_or_create_by!` lines for the welcome post to use `commenter_name` appropriately (e.g., "Riccardo", "Emiliano").
- [x] Task: Run seeds locally to verify logic
    - [x] Execute `bin/rails db:seed` and manually verify UI visually.
- [x] Task: Conductor - User Manual Verification 'Phase 3: Seeding and Polish' (Protocol in workflow.md)
