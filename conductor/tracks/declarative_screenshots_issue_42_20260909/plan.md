# Implementation Plan: Declarative Workshop Screenshots (Issue #42)

## Phase 1: Declarative Schema & Visualizer Pipeline

- [x] Task: TDD - Add schema validation tests for declarative screenshots in `workshop/skeleton.yaml`
    - [x] Add unit test verifying parsing of `screenshots:` block in `test/test_workshop_skeleton.rb`
    - [x] Ensure test fails before schema update (Red)
- [x] Task: Extend `workshop/skeleton.yaml` with sample screenshot declarations
    - [x] Define initial screenshot specs for `step-2` (Home ephemeral badge) and `step-4` (New Post / Admin)
    - [x] Validate skeleton tests pass (Green)
- [x] Task: Update Visualizer & Asset Sync (`build_ghpages.rb` & `server.rb`)
    - [x] Ensure `workshop/assets/screenshots/` directory is automatically created and copied to `workshop/build/assets/screenshots/` during build
    - [x] Serve `/assets/screenshots/*` dynamically in `workshop/visualizer/server.rb`
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 2: Playwright Runner & Script Architecture

- [x] Task: TDD - Write automated runner unit test in `test/test_workshop_screenshots.rb`
    - [x] Test CLI parsing, script discovery, and dry-run validation
    - [x] Verify test fails initially (Red)
- [x] Task: Setup Playwright Runner Harness
    - [x] Create `workshop/package.json` with `@playwright/test` or lightweight Playwright runner script
    - [x] Implement `workshop/screenshots/runner.js` to parse `workshop/skeleton.yaml` or CLI arguments and trigger Playwright
    - [x] Support multi-language script dispatch (Node Playwright vs Ruby / Shell scripts)
- [x] Task: Create Reference Screenshot Scripts
    - [x] Implement `workshop/screenshots/step2_home_ephemeral.playwright.js` (navigates to localhost:3000, checks badge, captures 1280x800 desktop frame)
    - [x] Implement `workshop/screenshots/step4_admin_article.playwright.js` (logs in via HTTP auth / form, navigates to new post, captures form)
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 3: Task Runner Integration & Diagnostics (`justfile`)

- [ ] Task: Add `just` recipes in root `justfile`
    - [ ] Add `just screenshots [filter]` recipe
    - [ ] Add `just test-screenshots` recipe for validation without requiring live server
- [ ] Task: Integrate into `just workshop-test` Diagnostics
    - [ ] Add diagnostic check confirming declarative screenshots are valid and asset links resolve
- [ ] Task: Documentation & Codelab Markdown Directives
    - [ ] Document usage in `workshop/README.md`
    - [ ] Add example comment directives in `workshop/CODELAB.md`
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)
