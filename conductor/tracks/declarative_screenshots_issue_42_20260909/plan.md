# Implementation Plan: Declarative Workshop Screenshots (Issue #42)

## Phase 1: Declarative Schema & Visualizer Pipeline

- [ ] Task: TDD - Add schema validation tests for declarative screenshots in `workshop/skeleton.yaml`
    - [ ] Add unit test verifying parsing of `screenshots:` block in `test/test_workshop_skeleton.rb`
    - [ ] Ensure test fails before schema update (Red)
- [ ] Task: Extend `workshop/skeleton.yaml` with sample screenshot declarations
    - [ ] Define initial screenshot specs for `step-2` (Home ephemeral badge) and `step-4` (New Post / Admin)
    - [ ] Validate skeleton tests pass (Green)
- [ ] Task: Update Visualizer & Asset Sync (`build_ghpages.rb` & `server.rb`)
    - [ ] Ensure `workshop/assets/screenshots/` directory is automatically created and copied to `workshop/build/assets/screenshots/` during build
    - [ ] Serve `/assets/screenshots/*` dynamically in `workshop/visualizer/server.rb`
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 2: Playwright Runner & Script Architecture

- [ ] Task: TDD - Write automated runner unit test in `test/test_workshop_screenshots.rb`
    - [ ] Test CLI parsing, script discovery, and dry-run validation
    - [ ] Verify test fails initially (Red)
- [ ] Task: Setup Playwright Runner Harness
    - [ ] Create `workshop/package.json` with `@playwright/test` or lightweight Playwright runner script
    - [ ] Implement `workshop/screenshots/runner.js` to parse `workshop/skeleton.yaml` or CLI arguments and trigger Playwright
    - [ ] Support multi-language script dispatch (Node Playwright vs Ruby / Shell scripts)
- [ ] Task: Create Reference Screenshot Scripts
    - [ ] Implement `workshop/screenshots/step2_home_ephemeral.playwright.js` (navigates to localhost:3000, checks badge, captures 1280x800 desktop frame)
    - [ ] Implement `workshop/screenshots/step4_admin_article.playwright.js` (logs in via HTTP auth / form, navigates to new post, captures form)
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

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
