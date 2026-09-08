# Implementation Plan: Workshop UI Alerts Hub & Admin Bootstrap Guard

## Phase 1: Workshop Alerts Hub Architecture
- [ ] Task: Create `blog/app/views/workshop/alerts/` directory
- [ ] Task: Move `_check_stuck_jobs.html.erb` to `blog/app/views/workshop/alerts/_stuck_jobs.html.erb`
- [ ] Task: Create `blog/app/views/workshop/alerts/_missing_admin.html.erb`
- [ ] Task: Create `blog/app/views/workshop/alerts/_hub.html.erb` and wire into `blog/app/views/layouts/application.html.erb`
- [ ] Task: Phase Verification & Checkpoint (Verify partials render cleanly without errors)

## Phase 2: db:seed Guard Gate & Admin Bootstrap
- [ ] Task: Update `blog/db/seeds.rb` with strict verification for `ADMIN_EMAIL` and `ADMIN_PASSWORD`
- [ ] Task: Phase Verification & Checkpoint (Verify db:seed aborts when ADMIN_EMAIL is missing)

## Phase 3: Automated Integration Tests & Documentation
- [ ] Task: Update and expand integration tests in `blog/test/integration/`
  - [ ] Test that `_missing_admin` alert renders when `User.count == 0` and hides when user exists
  - [ ] Test that `_stuck_jobs` alert still passes all previous assertions
- [ ] Task: Run test suite via `just test` (or `ruby test/test_workshop_diagnostics.rb`)
- [ ] Task: Update CHANGELOG.md, bump VERSION to 0.1.28
- [ ] Task: Phase Verification & Checkpoint (All tests green, working tree clean)
