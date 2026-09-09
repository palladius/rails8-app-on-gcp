# 📸 Auto-Screenshots Directory

> **Context & Origin:** Built as part of GitHub Issue [#42: [workshop] declarative screenshots](https://github.com/palladius/rails8-app-on-gcp/issues/42).

## 🎯 What We Are Building Here

This directory contains **automatically generated visual artifacts** captured by our declarative screenshot automation engine for the Rails 8 on Google Cloud workshop and codelab.

Rather than taking manual, out-of-date desktop screenshots, each screenshot in this folder:
1. Is **declared** in `workshop/skeleton.yaml` under each step's `screenshots:` block.
2. Has a dedicated **Playwright script** under `workshop/screenshots/` (e.g. `.playwright.js`).
3. Produces a high-resolution PNG (`<id>.png`) alongside rich execution **telemetry metadata** (`<id>.json`).
4. Is embedded in `workshop/CODELAB.md` using declarative HTML comment directives:
   ```markdown
   <!-- workshop-screenshot: id="step-2-home-ephemeral" -->
   ![Blog Homepage with Ephemeral DB Badge](assets/auto-screenshots/step-2-home-ephemeral.png)
   ```

## 📋 Metadata Recorded on Capture

Every generated image is accompanied by an audit metadata JSON file recording:
- **`recorded_at`**: Timestamp of when the frame was captured.
- **`computer_name`**: Host machine where the script ran.
- **`git_commit` & `git_branch`**: Exact git revision of the codebase at capture time.
- **`app_version`**: Rails 8 on GCP project version from `VERSION`.
- **`rails_env` & `base_url`**: Environment mode and server target (e.g. `development`, `production`, `http://localhost:3000`).
- **`viewport`**: Screen resolution (e.g. `1280x800`).

## 🛠️ Commands

- Validate all declarative screenshot scripts (dry-run, <0.05s):
  ```bash
  just test-screenshots
  ```

- Capture all declared screenshots:
  ```bash
  just screenshots
  ```

- Capture a specific step or screenshot ID:
  ```bash
  just screenshots step-2
  just screenshots step-2-home-ephemeral
  ```
