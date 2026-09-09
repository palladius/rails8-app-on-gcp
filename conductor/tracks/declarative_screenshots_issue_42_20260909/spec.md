# Specification: Declarative Workshop Screenshots (Issue #42)

## 1. Overview
The Rails 8 on Google Cloud workshop and codelab documentation require visual walkthroughs showing actual application state at various milestone steps (e.g., initial local dev homepage, creating an article, Cloud SQL persistent status badge, login flows, Nano Banana cover generation).

To keep screenshots reproducible, version-controlled, and self-healing across design or copy iterations, this track introduces a **declarative screenshot framework**. Each screenshot is defined declaratively (in `workshop/skeleton.yaml` and embedded in Markdown via directives/comments) with its corresponding programmatic capture script under `workshop/screenshots/` powered by Playwright.

## 2. Functional Requirements

### 2.1 Declarative Schema & Anchors
- **`workshop/skeleton.yaml` Integration:**
  Each workshop step can optionally declare a `screenshots:` collection:
  ```yaml
  steps:
    - id: "step-2"
      number: 2
      title: "Local Development & EPHEMERAL Badges"
      screenshots:
        - id: "step-2-home-ephemeral"
          title: "Blog Homepage with EPHEMERAL badge"
          description: "Shows localhost:8080 or localhost:3000 with the yellow ephemeral DB badge"
          output_path: "workshop/assets/screenshots/step-2-home-ephemeral.png"
          script: "workshop/screenshots/step2_home.playwright.js" # or .rb / .sh
          viewport: { width: 1280, height: 800 }
          selector: "body" # or fullPage: true
  ```
- **Markdown Directives / Comments:**
  Within `workshop/CODELAB.md` or step markdown files, authors can reference declarative screenshots using standardized directives:
  ```markdown
  <!-- workshop-screenshot: id="step-2-home-ephemeral" -->
  ![Blog Homepage with EPHEMERAL badge](assets/screenshots/step-2-home-ephemeral.png)
  ```

### 2.2 Execution Engine & Tooling
- **Playwright Runner:**
  - Automated Node.js scripts using `@playwright/test` or `playwright` CLI via `npx playwright`.
  - Supports headless Chromium.
  - Configuration in `workshop/playwright.config.js` or `package.json` with sensible defaults (viewport `1280x800` desktop, optional mobile emulation `390x844`).
- **Pluggable Architecture:**
  - The framework must allow scripts written in JavaScript/TypeScript (`.playwright.js`), Ruby (`.rb`), or Shell (`.sh`) by checking file extension and executing accordingly.

### 2.3 CLI & Task Runner Orchestration
- **`justfile` Recipes:**
  - `just screenshots [filter]`: Captures all declarative screenshots or filters by step / id (e.g. `just screenshots step-2`, `just screenshot step-2-home-ephemeral`).
  - `just test-screenshots`: Verifies that all declared scripts exist, required target output directories exist, and syntax passes linter/dry-run checks.
- **Diagnostics Suite Integration:**
  - Integration into `just workshop-test` to verify screenshot asset integrity and script executable presence without requiring a live server unless explicitly requested.

### 2.4 Artifact Generation & Asset Flow
- Rendered screenshots land in `workshop/assets/screenshots/<id>.png`.
- Visualizer build script (`ruby workshop/visualizer/build_ghpages.rb` and `server.rb`) automatically discovers, copies, and serves `workshop/assets/screenshots/` into `workshop/build/assets/screenshots/`.

## 3. Non-Functional Requirements
- **Deterministic & Headless:** Screenshots must run reliably without opening GUI windows.
- **Graceful Failure & Clear Diagnostics:** If the local Rails server is not running or credentials are missing, clear error output should guide the user (e.g. *"Rails server not detected on http://localhost:3000. Run 'just dev' first."*).
- **Fast Execution:** Target execution under 3 seconds per captured frame.

## 4. Acceptance Criteria
- [ ] Schema in `workshop/skeleton.yaml` extended with declarative `screenshots` field.
- [ ] Playwright runner runner script (`workshop/screenshots/runner.js` or `bin/workshop-screenshots`) created.
- [ ] At least 2 reference declarative screenshot scripts implemented (e.g. Homepage with badge, Admin login / New Article).
- [ ] `just screenshots` and `just test-screenshots` recipes functional in root `justfile`.
- [ ] `workshop/visualizer/build_ghpages.rb` and `server.rb` updated to mirror `workshop/assets/screenshots/` into `workshop/build/assets/screenshots/`.
- [ ] Automated tests in `test/test_workshop_screenshots.rb` passing.
