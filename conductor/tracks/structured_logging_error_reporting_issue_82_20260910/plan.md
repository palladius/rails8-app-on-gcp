# Implementation Plan: Native Google Cloud Structured JSON Logging & Error Reporting (Issue #82)

## Phase 1: Automated Baseline & "Before" Error UI Capture

- [x] Task: Capture Baseline Error UI (Red/Playwright) [954ce27]
    - [x] Create `workshop/screenshots/issue82_error_before.playwright.js` to capture the existing generic Rails `public/500.html` error UI
    - [x] Save "Before" screenshot to `workshop/assets/screenshots/issue-82-error-before.png`
    - [x] Register declarative screenshot in `workshop/skeleton.yaml`
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 2: Native Google Cloud JSON Logging Formatter

- [ ] Task: Write Failing Unit Tests for GoogleJsonFormatter (Red Phase)
    - [ ] Create `blog/test/lib/google_json_formatter_test.rb` validating JSON structure, severity mapping, timestamp formatting, trace ID injection, and nil/binary handling
    - [ ] Run `bin/rails test test/lib/google_json_formatter_test.rb` and verify tests fail
- [ ] Task: Implement GoogleJsonFormatter (Green Phase)
    - [ ] Implement `GoogleJsonFormatter < ActiveSupport::Logger::SimpleFormatter` in `blog/lib/google_json_formatter.rb`
    - [ ] Configure `config.logger` in `blog/config/environments/production.rb` and allow activation in any environment via `LOG_FORMAT=json`
    - [ ] Run tests and verify 100% pass
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 3: Error Reporting STDERR Hook & Diagnostic Demo Route (`/boom`)

- [ ] Task: Write Failing Tests for `/boom` & Error Reporting to STDERR (Red Phase)
    - [ ] Create test in `blog/test/controllers/boom_controller_test.rb` asserting `/boom` triggers 500 and emits formatted exception to stderr
    - [ ] Run tests and verify they fail
- [ ] Task: Implement `/boom` Diagnostic Endpoint & STDERR Cloud Error Reporting (Green Phase)
    - [ ] Add `GET /boom` route in `blog/config/routes.rb` and controller action in `blog/app/controllers/boom_controller.rb`
    - [ ] Add unhandled exception logging hook emitting exception name, message, and backtrace to `$stderr` formatted for GCP Error Reporting
    - [ ] Run tests and verify all pass
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 4: Googley 500 Error UI Modernization & "After" Brag Screenshot

- [ ] Task: Modernize `blog/public/500.html` to Google/Gemini Guidelines
    - [ ] Redesign `blog/public/500.html` with clean Googley card styling, smooth gradient accents, friendly robot/error illustration, request ID placeholder, and "Back to Home" button
- [ ] Task: Capture Automated "After" Screenshot & Run Verification
    - [ ] Create Playwright capture script `workshop/screenshots/issue82_error_after.playwright.js`
    - [ ] Execute Playwright script to capture `workshop/assets/screenshots/issue-82-error-after.png`
    - [ ] Verify `just test` and `just test-screenshots` pass cleanly
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)
