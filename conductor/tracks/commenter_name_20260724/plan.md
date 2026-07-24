# Implementation Plan

## Phase 1: Database and Model Updates
- [ ] Task: Generate database migration
    - [ ] Create migration to add `user_id` (references, optional) and `commenter_name` (string) to `comments` table.
    - [ ] Run `bin/rails db:migrate`.
- [ ] Task: Update Comment model
    - [ ] Add `belongs_to :user, optional: true` to `app/models/comment.rb`.
    - [ ] Implement `author_name` method with fallback logic (User's name -> `commenter_name` -> "Anonymous").
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Database and Model Updates' (Protocol in workflow.md)

## Phase 2: User Interface Updates
- [ ] Task: Update Comment form
    - [ ] Modify `app/views/comments/_form.html.erb` to include a `commenter_name` field for guests.
- [ ] Task: Update Comment display
    - [ ] Modify `app/views/comments/_comment.html.erb` to bold the author's name (`**<%= comment.author_name %>:**`).
- [ ] Task: Conductor - User Manual Verification 'Phase 2: User Interface Updates' (Protocol in workflow.md)

## Phase 3: Seeding and Polish
- [ ] Task: Update `db/seeds.rb`
    - [ ] Adjust `find_or_create_by!` lines for the welcome post to use `commenter_name` appropriately (e.g., "Riccardo", "Emiliano").
- [ ] Task: Run seeds locally to verify logic
    - [ ] Execute `bin/rails db:seed` and manually verify UI visually.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Seeding and Polish' (Protocol in workflow.md)
