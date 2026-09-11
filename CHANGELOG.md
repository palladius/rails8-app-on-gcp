All notable changes to this project will be documented in this file.

## [0.2.40] - 2026-09-11
### Fixed
- 💎 **Ruby 3.4.5 Named as the Real Prerequisite (PR #117, closes #116)**:
  - Step 2 asks for `bundle install`, `bin/rails db:setup` and `bin/rails db:seed`, but nothing ever told attendees to install the pinned Ruby — all three die with ``rbenv: version `3.4.5' is not installed (set by .../blog/.ruby-version)``.
  - The prerequisite was not merely missing, it was **wrong**: Step 0 and `skeleton.yaml` both said "Ruby 3.3+", while `blog/.ruby-version` and `blog/Dockerfile` pin **exactly 3.4.5**. Someone on 3.3 or 4.0 ticks the box and is still blocked the moment they `cd blog`.
  - Step 0 now names 3.4.5, shows the failure, gives `rbenv` / `rvm` / `asdf` install one-liners and says to verify **inside `blog/`**; Step 2 adds `ruby -v` to the first block plus a recovery callout quoting the rbenv error verbatim.
  - Corrected the `step-0-ruby-env` eval description, which claimed to check the project's Ruby but measures the harness interpreter: `bin/workshop_eval.rb` runs `eval(code)` in its own process, so `RUBY_VERSION` is whatever launched the harness — a machine defaulting to 4.0.5 scored 6/6 green while `cd blog` failed.
  - Documented in #116 why this cannot be converted into a shell eval: rbenv prepends the concrete version's bin directory to `PATH` for the running process, so every child `ruby` resolves to the harness interpreter and never consults `blog/.ruby-version`; unsetting `RBENV_VERSION`, `RBENV_DIR`, `RUBYLIB` or `RUBYOPT` does not change it.

## [0.2.39] - 2026-09-11
### Fixed
- 📁 **Step 2 Now Says `cd blog` (PR #115, closes #114)**:
  - Step 2 of `workshop/CODELAB.md` was written for a working directory it never puts the reader in. Step 0 ends with `cd rails8-app-on-gcp` and Step 1 with `cd ..`, so attendees reach Step 2 in the repo root — where `bundle install`, `bin/rails db:setup`, `bin/rails db:seed`, `bin/rails console` and `docker compose up` **all fail**, the last with `no configuration file provided: not found`. `Gemfile`, `bin/rails` and `compose.yaml` live in `blog/`.
  - Added an explicit `cd blog` to the first Step 2 code block plus a "Mind the directory!" callout, and a pointer to `just install` / `just compose-up`, which handle the directory themselves.
  - Fixed the same bug in `workshop/skeleton.yaml` step-2 pseudocode: `cp .env.dist .env` created the file in the repo root, where **`dotenv-rails` never reads it** — it loads `Rails.root.join(".env")`, i.e. `blog/.env` (`dotenv-3.1.8/lib/dotenv/rails.rb:46,57`). Now `cp .env.dist blog/.env`, followed by `cd blog`. Added the directory requirement to `step-2.prerequisites` and recompiled `SKELETON.md`.
  - This single omission had already produced **two** bullets in an earlier friction log (the compose failure and the `db:seed` `.env` failure) before costing a third attendee time. The repo already knew: `README.md` documents `cd blog && docker compose up -d`, every justfile recipe is `cd blog && …`, and step-2's own eval is `cd blog && bin/rails test` — the eval knew about `blog/`, the human-facing instructions did not.

## [0.2.38] - 2026-09-11
### Fixed & Improved
- 🛠️ **Friction Log FL006 (Steps 4→8 Deployment & Broken Images Evals, PR #113, closes #96)**:
  - **Secret Leak Hardening (FL006-14)**: Added `/database_url/i` to `secret_patterns` in `StatusesController` to prevent sensitive credentials from leaking into `/status.json`.
  - **Cloud SQL Sidecar Telemetry (FL006-15)**: Enhanced database tier detection when running on Cloud Run (`K_SERVICE` set) with localhost Cloud SQL Auth Proxy sidecar.
  - **Multi-DB Schema Loading (FL006-16/17)**: Documented `db:schema:load:queue/cache/cable` and the 4 `DATABASE_*_URL` environment variables in `CODELAB.md`.
  - **URI Socket Format (FL006-18)**: Added warnings and guidance for Ruby 3.4+ URI parser with Cloud SQL proxy sockets.
  - **Step 6 Multi-Database Migrations (FL006-19)**: Expanded Step 6 deployment procedure in `CODELAB.md`.
  - **Broken Images Evaluator (FL006-20)**: Added `step-7-ruby-no-broken-images` eval to `workshop/skeleton.yaml` checking for orphan ActiveStorage blobs.

## [0.2.27] - 2026-09-11
### Added & Improved
- 🏷️ **Workshop Hive Leaderboard Footer Version & Status Formatting**:
  - Embedded version badge (`v0.1.6`) directly into the leaderboard footer for instant visual verification.
  - Formatted down HTTP codes as `/<code >` (e.g. `/503`) instead of `H503` for sleeker telemetry display.
  - Bumped `workshop/hive/VERSION` to `0.1.6`.

## [0.2.26] - 2026-09-11
### Fixed
- 🐞 **Workshop Hive Leaderboard Client-Side Compact Scope Fix**:
  - Resolved `ReferenceError: compact is not defined` in `renderTable()` by scoping `const compact = isCompactMode()` properly across student row loops.
  - Bumped `workshop/hive/VERSION` to `0.1.5`.

## [0.2.25] - 2026-09-11
### Added & Improved
- 📐 **Workshop Hive Leaderboard High-Density 50+ Compact View (Single-Line Row Mode)**:
  - Added dedicated **Compact Mode** (`View: Compact (50+)` / `View: Full`) toggle button in `workshop/hive` header toolbar with `localStorage` persistence and URL sync (`?compact=true`).
  - Implemented strict **Single-Line Student Rows** (`whitespace-nowrap`, row height `30px`, `py-1`):
    - Inline status dot (🟢/🔴) + latency in ms.
    - `HH:MM` timestamp, student nickname (truncated with hover tooltip), and medals/trophies.
    - 8-segment progress bar.
    - Cloud Run direct link with service logo.
    - Raw `/status.json` endpoint direct link.
    - Ruby & Rails version chips, Rails environment badge (`prod`/`dev`), and GCP Triad indicators (`🐘 ☁️ 🍌`).
  - Adapted Step 8 Champions Podium to a low-profile slim strip in compact mode, maximizing vertical screen real estate for 50+ students on a single screen without scrolling.
  - Bumped `workshop/hive/VERSION` to `0.1.4`.

## [0.2.24] - 2026-09-11
### Added
- 🍯 **Workshop Hive Structured Telemetry JSON Endpoints (`/index.json`, `/status.json`, `/metastatus.json`)**:
  - Added `GET /index.json`, `GET /status.json`, and `GET /metastatus.json` to Workshop Hive, exposing aggregated student telemetry with direct links to student Cloud Run endpoints (`url`), status JSONs (`status_url`), and up healthcheck endpoints (`up_url`).
  - Added HTTP content negotiation on `GET /` to return JSON when `Accept: application/json` is requested.
  - Implemented query string persistence (`query_params: params`) and event metadata tracking (`event_name`, `event_start`, `elapsed_minutes`, `cinderella_hours_remaining`).
  - Added unit test suite in `test_api_leaderboard.rb`.

## [0.2.23] - 2026-09-11
### Fixed & Added
- 🐝 **Workshop Hive Leaderboard Duplicate Cloud Run Deduplication & Toggle**:
  - Implemented `deduplicate_by_url` and `normalize_url` in `WorkshopHive::SheetsReader` to eliminate duplicate Cloud Run submissions by keeping the second (latest) entry by default.
  - Added `&show_duplicates=true` (and typo-tolerant `&show_duplicatees_true`) query parameter support in `GET /api/leaderboard` to opt out of deduplication and view all raw submissions.
  - Added interactive duplicate toggle pill (`👯 Dupes: Off/ON`) in `public/index.html` and `public/js/hive.js`.
  - Normalized URLs (whitespace trimming, case-insensitivity, trailing slash removal, and protocol scheme handling for `.run.app` domains).
  - Added full test coverage for both default deduplication and opt-out duplicate display in `test_sheets_reader.rb` and `test_api_leaderboard.rb`.

## [0.2.22] - 2026-09-11
### Changed
- 📐 **Codelab Page 1 Layout Modernization & Diagram Refinements**:
  - Reordered Page 1 (Overview) in `workshop/CODELAB.md` to place the Target Reference Architecture (**Variant 1: Clean Flat Vector Enterprise**) and evolution GIF prominently *above* the "What you'll learn" section.
  - Refined deterministic architecture diagram generator (`diagrams/generate_diagrams.py`) with compact service identifiers (`S1`..`S7`), cleaner edge routing, and updated canonical diagram assets (`assets/arch_diagram.png`).

## [0.2.21] - 2026-09-10
### Added
- 🧪 **Workshop Status Telemetry Inference Evals (Steps 5, 6, 7)**:
  - Added unit test cases to `StatusesControllerTest` asserting deterministic step inference for Step 5 (Cloud SQL local storage), Step 6 (Cloud Run non-AI baseline), and Step 7 (Cloud Run + Cloud SQL + GCS + active AI).
  - Added programmatic step evaluations in `workshop/skeleton.yaml` and asserted in `test/test_workshop_skeleton.rb`.

## [0.2.20] - 2026-09-10
### Fixed
- 🛠️ **Billing API Error Handling & Worktree Bundle Cache Support (FL-003 / FL-004)**:
  - Enhanced `bin/workshop_diagnostics.rb` to gracefully catch disabled `cloudbilling.googleapis.com` API with remediation advice instead of crashing.
  - Added parent repo bundle cache discovery to `bin/workshop_uat.rb` when running in isolated git worktrees, preventing redundant `bundle install` overhead.
  - Added billing API enablement tip to `workshop/CODELAB.md`.

## [0.2.19] - 2026-09-10
### Added
- 🛡️ **Dedicated Cloud Build Service Account for CI/CD (Issue [#59](https://github.com/palladius/rails8-app-on-gcp/issues/59))**:
  - Implemented dedicated Bring-Your-Own-Service-Account (`rails-cloudbuild-sa`) in `iac/cicd.tf` following the Principle of Least Privilege (POLA).
  - Attached scoped roles: `roles/logging.logWriter`, `roles/artifactregistry.writer`, `roles/run.developer`, and `roles/iam.serviceAccountUser` acting on the Cloud Run runtime SA.

## [0.2.18] - 2026-09-10
### Added
- 🇮🇹 **DevFest Modena 2026 Premiere Date & Landing Portal Event Badge**:
  - Updated premier workshop date to Saturday 3 October 2026 (Sala 40, 10:30-13:30, 180 min).
  - Renamed event documentation hierarchy to `workshop/events/20261003-devfest-modena/`.
  - Added interactive DevFest event badge to the landing page visualizer (`workshop/visualizer/server.rb`) linking directly to event briefing documentation.

## [0.2.17] - 2026-09-10
### Added
- 📐 **Deterministic GCP Architecture Diagrams & Nano Banana Visual Reference (Issue [#66](https://github.com/palladius/rails8-app-on-gcp/issues/66))**:
  - Implemented deterministic Python `diagrams` & `uv` pipeline (`diagrams/generate_diagrams.py`) generating canonical GCP architecture graphics (`assets/arch_diagram.png`) with official icons and compact vertical multi-container Cloud Run layout.
  - Added progressive architecture evolution animated GIF (`assets/arch_evolution.gif`) tracking the Step 1 $\to$ Step 7 modernization path.
  - Integrated Gemini 3 Pro Image (Nano Banana Pro) architecture diagrams: Variant 1 (Flat Vector Enterprise `assets/nanobanana_arch_flat.png`) as Page 1 hero visual in Codelab and Skeleton, and Variant 2 (Isometric 3D `assets/nanobanana_arch_isometric.png`).
  - Added `just diagrams`, `just diagram`, `just diagram-evolution`, `just nanobanana`, and `just test-diagrams` (`test/test_architecture_diagram.rb`).

### Fixed
- 🪣 **ACTIVE_STORAGE_SERVICE Environment Injection & Workshop Compatibility (Issue [#91](https://github.com/palladius/rails8-app-on-gcp/issues/91))**:
  - Made `blog/config/environments/production.rb` dynamically respect `ENV["ACTIVE_STORAGE_SERVICE"]` (defaulting to `:google_prod`), allowing Cloud Run deployments with `--set-env-vars ACTIVE_STORAGE_SERVICE=...` to take effect in production.
  - Added service alias `google:` in `blog/config/storage.yml` (and `workshop/time-machine/stage-2-gcs/blog/config/storage.yml`) aliasing `google_prod`, ensuring full backwards and forward compatibility with workshop codelab instructions and CLI commands.
  - Updated time-machine stage 2 production configuration to match.

## [0.2.16] - 2026-09-10
### Added
- 🪵 **Native Google Cloud Structured JSON Logging & STDERR Error Reporting (Issue [#82](https://github.com/palladius/rails8-app-on-gcp/issues/82))**:
  - Implemented zero-gem `GoogleJsonFormatter` (`blog/lib/google_json_formatter.rb`) converting Rails logs to single-line structured JSON with Cloud Logging severity levels, ISO8601 timestamps, and `logging.googleapis.com/trace` context.
  - Wired `GoogleJsonFormatter` into `blog/config/environments/production.rb` with fallback (`LOG_FORMAT=plain`) and added initializer for local testing (`LOG_FORMAT=json`).
  - Added `CloudErrorReportingMiddleware` (`blog/config/initializers/error_reporting.rb`) piping unhandled exceptions and backtraces to `STDERR` for automated incident group clustering in Google Cloud Error Reporting.
  - Added diagnostic test route `GET /boom` (`BoomsController`) to safely test live Cloud Error Reporting on Cloud Run.
  - Modernized `blog/public/500.html` to Google/Gemini aesthetic guidelines with glassmorphism card, banana illustration, error reporting telemetry badges, and interactive navigation buttons.
  - Automated high-resolution "Before" and "After" screenshot captures via Playwright (`issue82_error_before.playwright.js`, `issue82_error_after.playwright.js`) integrated into `workshop/skeleton.yaml` and runnable via `just screenshots`.

## [0.2.15] - 2026-09-10
### Added
- 🏆 **Step 8 Proctor-Validated Graduation Trophy (Issue [#83](https://github.com/palladius/rails8-app-on-gcp/issues/83))**:
  - **Rails Telemetry (`StatusesController`)**: Added `detect_quest_status` to parse `ENV['STEP_8_GHI']` (numeric string or GitHub issue URL) and expose structured `quest` object in `/status.json`. Added `STEP_8_GHI` to `safe_env_inspection`.
  - **The Hive Backend (`workshop/hive/`)**: Created `WorkshopHive::ProctorReviewer` to verify GitHub issue comments from authorized proctors (`HIVE_PROCTORS="palladius,emilianodellacasa,ricc"`) containing case-insensitive `LGTM`, with in-memory 120s TTL caching and `Healthchecker` integration.
  - **The Hive Frontend (`public/js/hive.js`)**: Rendered 8/8 progress bar with purple/gold glowing effect and clickable golden trophy 🏆 linking to the approved GitHub issue. When awaiting review, displays `⏳ GHI #XX review pending` link badge.
  - **Codelab Instructions (`workshop/CODELAB.md`)**: Documented the 3-step proof-of-work graduation workflow at the conclusion of Step 8 and rebuilt static documentation via `just build-ghpages`.
- 🧪 **Workshop Status Telemetry Evaluation Suite (`status.json` Step Verification)**:
  - Added declarative ruby evaluations in `workshop/skeleton.yaml` for Steps 5, 6, and 7 asserting that `/status.json` auto-inference returns step numbers `5`, `6`, and `7` based on active infrastructure telemetry (Cloud SQL, GCS, and GenAI credentials).
  - Synchronized `workshop/SKELETON.md` via `just build-skeleton`.
  - Added test coverage in `test/test_workshop_skeleton.rb` and `blog/test/controllers/statuses_controller_test.rb`.

## [0.2.14] - 2026-09-10

## [0.2.12] - 2026-09-10
### Fixed
- 📸 **Step 7 Workshop UI Screenshot Clean-Up**:
  - Replaced `step-7-podcastifier-ui.png` with a clean, architecturally consistent view (`[CLOUD PERSISTENT]` banner, zero stuck jobs alert, authentic GCS cloud storage stamp and dual audio player).
- 🐝 **Workshop Hive Frontend Healthcheck Bugfix**:
  - Fixed missing `const data = await res.json()` in `workshop/hive/public/js/hive.js` `fetchHealth()` function, enabling real-time telemetry rendering and healthy count synchronization.

## [0.2.11] - 2026-09-10
### Added
- 🎙️ **Step 7 Podcastifier Showcase Assets & Audio Links**:
  - Embedded real screenshot of Podcastifier UI (`assets/auto-screenshots/step-7-podcastifier-ui.png`) showcasing dual audio players into Step 7 of `workshop/CODELAB.md`.
  - Added direct links to authentic Google Cloud TTS audio samples (`assets/audio/podcastifier_italian_overview.mp3` with `it-IT-Wavenet-A` and `podcastifier_english_overview.mp3` with `en-US-Wavenet-D`).
  - Attached assets and documentation to GitHub Issue [#72](https://github.com/palladius/rails8-app-on-gcp/issues/72).

## [0.2.10] - 2026-09-10
### Fixed
- 🛠️ **Virgin Project Provisioning & Deploy 1 Robustness (Issue [#72](https://github.com/palladius/rails8-app-on-gcp/issues/72))**:
  - Added explicit `google_project_service` for `run.googleapis.com` in `iac/cloudrun.tf` and `sqladmin.googleapis.com` in `iac/database.tf` to prevent cryptic Cloud Run "Internal Error code 7" on volume mounts.
  - Updated `iac/check_gcp_setup.sh` to proactively detect and grant least-privilege roles to the Default Compute SA (`storage.admin`, `logging.logWriter`, `artifactregistry.writer`, `cloudbuild.builds.builder`) preventing `PERMISSION_DENIED` on `gcloud run deploy --source`.
  - Updated `iac/secrets.tf` to detect local `master.key` or fallback to a valid 32-char hex string instead of invalid-length dummy text.
  - Documented `SECRET_KEY_BASE_DUMMY=1` in `workshop/CODELAB.md` Step 3 deployment command.

## [0.2.9] - 2026-09-10
### Added
- 🌐 **Workshop Landing Portal & Slides on GitHub Pages (`/slides/`, `/codelab/`)**:
  - Implemented clean, minimal landing portal page at root (`/` / `index.html`) offering direct navigation between Workshop Codelab and Presentation Slides.
  - Isolated multi-doc Google Codelab guide under `/codelab/`.
  - Added slide build and deployment into GitHub Pages (`workshop/build/slides/`, `.github/workflows/deploy-pages.yml`).
  - Added slide 1 self-QR code pointing directly to `https://palladius.github.io/rails8-app-on-gcp/slides/`.
  - Added bilingual language switcher with 🇬🇧 EN and 🇮🇹 IT flags with static mirror (`index_it.html`).
  - Added visual thumbnail previews to the portal destination cards with enlarged 420px previews (filling ~70% of card height) and compact typography.
  - Reordered portal navigation cards: **1. Presentation Slides** ("Get started with Antigravity, get credits and THEN start the workshop!") and **2. Workshop Codelab** ("When you have Antigravity installed and Billing enabled for GCP, you can start this codelab!").
  - Explicitly added `git` (2.30+) to workshop prerequisites checklist and evaluation specs (`CODELAB.md`, `skeleton.yaml`, `SKELETON.md`, and landing-page READMEs).
  - Added dedicated standalone slide verification test suite (`test/test_slides.rb`, `just test-slides`) testing against HTML/div escaping leaks, overflow, and image rendering.
  - Improved Slide 2 (Antigravity download) with gray down arrow ⬇️, standalone button, and small URL caption.
  - Polished Slide 5 with CSS class-based prompt styling and copy button.
  - Enhanced final Slide 6 with author avatars alongside LinkedIn links and compact workshop anthem audio player.
  - Introduced `workshop/events/YYYYMMDD-EVENT_NAME/` directory hierarchy for tracking workshop deliveries, initialized with `20261003-devfest-modena/`.
- 🏆 **Workshop BRAG Document & Autonomous Engineering Architecture (PR [#61](https://github.com/palladius/rails8-app-on-gcp/pull/61), PR [#62](https://github.com/palladius/rails8-app-on-gcp/pull/62), Fixes [#60](https://github.com/palladius/rails8-app-on-gcp/issues/60))**:
  - Published comprehensive Workshop BRAG document [`docs/WORKSHOP_BRAG_DOCUMENT.md`](docs/WORKSHOP_BRAG_DOCUMENT.md) detailing both Pillar 1 (Enterprise Multi-Container Serverless Architecture) and Pillar 2 (Agent-First Autonomous Engineering & Self-Healing Metamodel).
  - Documented the **Agent-First Native Architecture**: Antigravity landing page guidance, custom repository skills (`skills/rails8app-workshop`, `skills/cloud-run-troubleshooting`), and in-app diagnostics.
  - Documented the **Declarative SKELETON**: Machine-readable specification (`workshop/skeleton.yaml` $\to$ `workshop/SKELETON.md`) with actionable contracts (`prerequisites`, `pseudocode`, `postrequisites`) and 3-tier executable step evals (`[SHELL]`, `[RUBY]`, `[LLM]`).
  - Documented **Constitutional Invariants** (`docs/CONSTITUTION.md`), Zero-Branch Time Machine progression, and Hive real-time classroom observability with visual telemetry badges.
  - Added dual English architecture narrative and Italian community summary for Modena Ruby Day & meetups.

## [0.2.8] - 2026-09-09
### Added
- 🎶 **Workshop Anthem & Short Clip on Final Slide (`slides/index.md`, `slides/dist/index.html`)**:
  - Added HTML5 audio player widget with "Check this great song" to the concluding presentation slide.
  - Linked the 30-second Lyria 3 clip preview and the full-length 3-minute energetic acoustic guitar composition (Lyria 3 Pro on Vertex AI) generated for Rubyists.

### Fixed
- 🛠️ **Terraform Provider 5.x & Virgin Project Hardening (FL-004)**:
  - Fixed `iac/iap.tf`: In Google provider 5.x+, static `iap { enabled = true }` threw schema validation errors (`oauth2_client_id` and `oauth2_client_secret` required) even when `enable_iap = false`. Converted to optional `dynamic "iap"` block.
  - Added `iap_client_id` and `iap_client_secret` (default `""`) to `iac/variables.tf`.
  - Added `enable_cicd_trigger` (default `false`) to `iac/variables.tf` and conditioned `google_cloudbuild_trigger.deploy_on_push` in `iac/cicd.tf` to avoid BYOSA enforcement failures in clean attendee projects.
  - Verified live Terraform execution on brand-new virgin project `rails8-workshop-fl04` with 20/20 evals passed.

## [0.2.7] - 2026-09-09
### Added
- 📸 **Declarative Workshop Screenshots (Issue [#42](https://github.com/palladius/rails8-app-on-gcp/issues/42))**:
  - Declarative screenshot specification integrated into `workshop/skeleton.yaml` under step declarations.
  - Automated Playwright runner (`workshop/screenshots/runner.js`) with support for `--list`, `--dry-run`, and single step/id filters.
  - Reference Playwright scripts:
    - `workshop/screenshots/step2_home_ephemeral.playwright.js`
    - `workshop/screenshots/step4_gcs_stuck_jobs.playwright.js`
  - Integration with `justfile`: `just screenshots [filter]` and `just test-screenshots`.
  - Diagnostics suite check added to `bin/workshop_diagnostics.rb` (`just workshop-test`).
  - Markdown directives and documentation in `workshop/README.md` and `workshop/CODELAB.md`.
- 🐝 **Workshop Hive Cloud Run Deployment (`workshop/hive/bin/deploy`, `workshop/hive/.env`)**:
  - Added dedicated one-click deployer script `workshop/hive/bin/deploy` that sources project configuration from local `workshop/hive/.env`.
  - Added `workshop/hive/.env.dist` blueprint template with `PROJECT_ID=palladius-genai`.
  - Integrated official Cloud Run service icon, hover-based service names with clean revision tags, and Rails environment badges (`prod`, `dev`, `test`).
  - Added direct link `🐝 Hive` in the Rails Blog layout footer pointing to the live Cloud Run leaderboard.

## [0.2.6] - 2026-09-09
### Added
- 💰 **Real-Time Workshop Cost Estimator (`bin/rails8app-billing`, `just billing-estimate`)**:
  - Implemented live Ruby FinOps cost calculator tailored for attendees operating on $5.00 GDP promotional credits.
  - Bypasses the 6–24 hour Google Cloud Billing report delay by combining live resource discovery (Cloud SQL instance tier & SSD size, Cloud Run active status, GCS storage buckets) with Cloud Monitoring API telemetry for Vertex AI.
  - Computes remaining credit budget, health indicator, and alert thresholds to avoid surprise billing.
- 🎶 **Official Workshop Anthem in README**:
  - Added direct link to the high-fidelity acoustic guitar track generated by Google Lyria 3 Pro on Vertex AI.

## [0.2.5] - 2026-09-09
### Added
- 🐝 **Workshop Hive Leaderboard Registration Callout (`workshop/CODELAB.md`)**:
  - Bumped Codelab curriculum version to `v2.0.1alpha`.
  - Added direct registration Google Form link in Step 3 for workshop attendees to submit their Cloud Run URL and appear live on the proctor's Hive Leaderboard.

## [0.2.4] - 2026-09-09
### Added
- 🪣 **Sub-Second Storage Objects Telemetry (`StatusesController` & `check_gcp_setup.sh`)**:
  - Added `blobs_count` and `attachments_count` to `/status.json` and `StatusesController` (computed in ~1ms via ActiveStorage).
  - Optimized `iac/check_gcp_setup.sh` to use direct `gcloud storage objects list` instead of slow recursive wildcard descent.
  - Surfaced Media Blobs count directly in `just cloud-run-status` summary dashboard.

## [0.2.3] - 2026-09-09
### Added
- 🎙️ **Podcastifier Audio Pipeline (Step 7)**:
  - Added `CloudTtsService` for Italian TTS voice synthesis (`it-IT-Wavenet-A`) via Application Default Credentials (ADC) with graceful offline fallback.
  - Added `PodcastifierJob` and attached HTML5 `<audio controls>` player directly to post show view.
  - Added unit test `blog/test/models/solid_queue_configuration_test.rb` validating Solid Queue enqueuing and execution.
- 🛠️ **Troubleshooting Skills & Guidance**:
  - Added `skills/cloud-run-troubleshooting/SKILL.md` with targeted recipes for Cloud Run log investigation via `gcloud logging read`.
  - Added `skills/rails8app-workshop/SKILL.md` and failure modes reference `what-could-possibly-go-wrong.md`.
- 🚀 **`just cloud-run-status` Recipe & Telemetry Inspector (`bin/cloud_run_status.sh`)**:
  - Added `just cloud-run-status [url]` command to automatically infer the live Cloud Run endpoint via `terraform output -raw cloud_run_url` (or fallback via `gcloud run services describe`), fetch `/status.json`, and render a rich terminal telemetry dashboard.
  - Added standard Terraform outputs in `iac/outputs.tf` (`cloud_run_url`, `cloud_run_service_name`, `project_id`, `region`).
  - Supports `--json` and `--url-only` flags for scripting and CI/CD pipelines.

### Fixed
- 🐘 **Multi-Database Migrations in Cloud Run Entrypoint (`blog/bin/docker-entrypoint`)**:
  - Extended entrypoint to execute `db:prepare:queue`, `db:prepare:cache`, and `db:prepare:cable` alongside `primary` database preparation.
  - Automatically invokes `db:seed` on startup to bootstrap the admin user from `GOOGLE_CLOUD_ACCOUNT` and eliminate missing admin warnings.
- 🧭 **Status Controller & Telemetry Badge Robustness (`blog/app/controllers/statuses_controller.rb`)**:
  - Synchronized `APP_VERSION` to package `blog/VERSION` cleanly into Docker image.
  - Fixed `ADMIN_EMAIL` and `GOOGLE_CLOUD_REGION` / `GOOGLE_CLOUD_LOCATION` fallback resolution on `/status`.
- 🔀 **Step 3 Codelab Twist: The "Puma Workaround" Trap**:
  - Updated `workshop/CODELAB.md`, `workshop/SKELETON.md`, and `workshop/skeleton.yaml` with the pedagogical lesson of attempting `SOLID_QUEUE_IN_PUMA=true` on Cloud Run: jobs are drained, but container restart wipes out ephemeral SQLite data.

## [0.2.2] - 2026-09-09
### Fixed
- 🧪 **Workshop UAT Harness Sandbox Bundler Isolation (`bin/workshop_uat.rb`)**:
  - Replicated `blog/.bundle` directory into temporary sandbox workspaces alongside `vendor/bundle` cache, ensuring isolated `just workshop-uat` runs find locally vendored gems without requiring network installations.
  - Verified 100% passing automated evaluation and UAT test harness across all stages (`just workshop-eval all` -> 20/20 evals, `just workshop-uat 1/2/3/4/6`).

## [0.2.1] - 2026-09-09
### Added
- 📸 **Visual Architecture Diagrams & Screenshot Placeholders**:
  - Embedded canonical architectural diagrams across workshop steps: GCS IAM signing workflow, Secret Manager injection, Cloud SQL Auth Proxy security comparison, Cloud Run multi-container sidecars, and NanoBanana GenAI pipeline.
  - Added 19 targeted `TODO(riccardo): add screenshot <why and for what>` callouts throughout `workshop/CODELAB.md` covering key pedagogical UI milestones (Billing console, Mailpit inbox, ephemeral container reset shock, GCS console, secret bindings, multi-container sidecars tab, AI vintage posters, and Rails console blob rescue).


## [0.2.0] - 2026-09-09
### 🎉 Major Milestone: Rails 8 on Google Cloud Workshop v0.2.0 (WOWOW)
- 🚀 **Complete 8-Step, 3-Deployment Workshop Experience**:
  - **Deploy 1 (Step 3)**: The Stateless Shock — single-container Puma on Cloud Run in 3 minutes, proving the necessity of decoupled cloud persistence.
  - **Deploy 2 (Step 4)**: Google Cloud Storage with private IAM Credentials blob signing (`iam: true`), provenance stamp watermarks, and POLA stuck jobs warning banner.
  - **Deploy 3 (Step 6)**: Enterprise Multi-Container Sidecars — Puma web, Solid Queue worker, and Cloud SQL Auth Proxy mTLS sidecar on Cloud Run.
- ⏳ **Zero-Branch Time-Machine Progression**:
  - Developers stay comfortably on `main` using `just workshop-rewind 1`, `just workshop-rewind 2`, and `just workshop-restore-gold`.
- ⚙️ **Dedicated `gcloud` Configuration**:
  - Environment isolation via `rails8-on-gcp-workshop` named configuration, preventing collisions with corporate/personal setups.
- 🍌 **Asynchronous GenAI & GCS Treasure Hunt**:
  - NanoBanana 1960s vintage poster generator powered by Gemini 2.5 Flash on Vertex AI (with ADC), bilingual podcastifier TTS, and Rails console blob rescue.
- ⏱️ **Compact Page Durations**:
  - Estimated durations (*Duration: XXmin*) across all 11 pages of the codelab.
- 🧪 **Comprehensive Evaluation Engine**:
  - 100% passing automated evaluation suite (`just workshop-eval all` -> 20/20 evals passed).
- 🌐 **Live GitHub Pages Publication**:
  - Automatically compiled and deployed via GitHub Actions to https://palladius.github.io/rails8-app-on-gcp/.



## [0.1.44] - 2026-09-09
### Changed
- ⏱️ **Compact Duration Format**:
  - Formatted page completion estimates to compact italic style (*Duration: 15min*) across all pages in `workshop/CODELAB.md`.


## [0.1.43] - 2026-09-09
### Added
- ⏱️ **Page Duration Estimates in Codelab**:
  - Added estimated completion duration in italic (*Duration: XX minutes*) to the top of all 11 pages/steps in `workshop/CODELAB.md`.
  - Recompiled static multi-doc site (`workshop/build/`) for immediate GitHub Pages deployment.


## [0.1.42] - 2026-09-09
### Changed
- 🎨 **Cover Image Header Layout**:
  - Moved the "🔄 Regenerate Cover" button to the top header, positioned to the left of the cover image card in `posts#show`.
  - Added clean `.post-show__header-cover-wrapper` and `.post-action-btn--compact` CSS styles with responsive mobile stacking.

## [0.1.41] - 2026-09-09
### Added
- 🖼️ **Button to Delete & Regenerate Article Cover Image (Fixes [#34](https://github.com/palladius/rails8-app-on-gcp/issues/34))**:
  - Added member route `DELETE /posts/:id/purge_cover_image` to purge post cover image and re-enqueue `GenerateCoverImageJob` asynchronously.
  - Added "🔄 Regenerate Cover" button on `posts#show` hero actions and "🗑️ Delete & Regenerate Cover" button with image preview in `posts#edit` form.
  - Supports reactive Turbo Stream removal and broadcast updates via Turbo Streams.
  - Comprehensive integration/controller tests with test execution under 5 seconds.

## [0.1.40] - 2026-09-09
### Changed
- 📖 **Comprehensive Codelab Rewrite: Canonical 8 Steps & 3 Deployments (Fixes [#29](https://github.com/palladius/rails8-app-on-gcp/issues/29))**:
  - Fully rewritten `workshop/CODELAB.md` to align with `docs/CONSTITUTION.md` v1.1.0 and `workshop/skeleton.yaml`.
  - **Step 3 (Deploy 1 — The Stateless Shock)**: Single-container Puma deploy to Cloud Run (`just workshop-rewind 1`), early WOW in 3 minutes, followed by container scale-to-zero restart and lost ephemeral SQLite data.
  - **Step 4 (Deploy 2 — GCS Persistent Storage & POLA Warning)**: Private GCS ActiveStorage with IAM signed URLs (`just workshop-rewind 2`), cloud stamp provenance overlay, and pedagogical stuck jobs warning banner (`_check_stuck_jobs`).
  - **Step 5 (Cloud SQL Ready & Secret Manager)**: CLI-based secret injection into Google Cloud Secret Manager (`rails-master-key`, `rails-db-password`) and runtime Service Account permissions.
  - **Step 6 (Deploy 3 — Enterprise Multi-Container Sidecars)**: Restoring Gold Standard (`just workshop-restore-gold`), multi-container `compose.prod.yaml` (Puma web + Solid Queue worker + Cloud SQL Auth Proxy sidecar), and Cloud Run database migration jobs.
  - **Step 7 (Generative AI Pipelines & GCS Treasure Hunt)**: Asynchronous NanoBanana cover generation on Vertex AI, bilingual TTS podcastifier, and recovering Step 4 orphaned blobs via Rails console.
  - **Step 8 (Quests & Graduation)**: Zero-Trust IAP, SRE structured telemetry, and pgvector semantic search.
  - Recompiled static HTML site (`workshop/build/index.html`, `skeleton.html`, `constitution.html`) via `just build-ghpages`.


## [0.1.39] - 2026-09-09
### Added
- 🏠 **Resilient Storage Provenance Stamp Watermark UI Overlay (Issue [#18](https://github.com/palladius/rails8-app-on-gcp/issues/18))**:
  - Implemented `cover_image_stamp_tag` helper in `blog/app/helpers/application_helper.rb` and responsive glass CSS overlay in `blog/app/assets/stylesheets/application.css`.
  - Stamps the bottom-right corner of cover images with `nanobanana_stamp_local.png` (the "casetta" / `127.0.0.1` ephemeral disk badge) when `storage_tier == :local`, and `nanobanana_stamp_cloud.png` when `storage_tier == :gcs`.
  - Ensures the visual provenance cue is 100% visible across all platforms, on both user-uploaded and AI-generated covers, without requiring host C-dependencies (`libvips.so.42`).
  - Added unit test coverage in `blog/test/helpers/application_helper_test.rb`.
- ⚙️ **Dedicated `gcloud` Named Configuration & Multi-Account Isolation (Issue [#38](https://github.com/palladius/rails8-app-on-gcp/issues/38))**:
  - Integrated `rails8-on-gcp-workshop` dedicated configuration in `workshop/CODELAB.md` and `workshop/skeleton.yaml` to isolate CLI properties from users' unrelated corporate or personal GCP projects.
  - Enhanced `bin/workshop_diagnostics.rb` to display active gcloud configuration and inject `--account` and `--billing-project` flags to reliably support developers logged into multiple Google accounts.

## [0.1.38] - 2026-09-09
### Changed
- 🌐 **Purged `GCP_PROJECT_ID` & Standardized Environment Variables**:
  - Completely purged legacy `GCP_PROJECT_ID` across codebase, tests, scripts, and documentation in favor of canonical `GOOGLE_CLOUD_PROJECT`.
  - Also purged deprecated `GCP_REGION` (replaced with `GOOGLE_CLOUD_REGION`) and `GCP_EMAIL` (replaced with `GOOGLE_CLOUD_ACCOUNT`).
  - Added strict anti-legacy guards in `bin/workshop_diagnostics.rb` and automated regression tests in `test/test_workshop_diagnostics.rb` to fail fast if any `GCP_*` variables are present in `.env`.
### Added
- 📜 **Environment Variable Standard Specification**:
  - Created [`docs/ENV_VAR_NAMES.md`](file:///docs/ENV_VAR_NAMES.md) documenting approved canonical variables, rationales, and the strict denylist of prohibited legacy prefixes.

## [0.1.37] - 2026-09-09
### Added
- 🧭 **Secret `/status` Telemetry Dashboard (Resolves [#35](https://github.com/palladius/rails8-app-on-gcp/issues/35))**:
  - Implemented unlinked, secret `/status` HTML dashboard and `/status.json` endpoint for professors and workshop instructors.
  - **Workshop Step Auto-Inference**: Deduces the student's active step (Steps 1–8) in 0 ms based on live infrastructure telemetry (database adapter, ActiveStorage backend, Cloud Run vs Docker runtime, and AI availability), or via `ENV["WORKSHOP_STEP"]`.
  - **Safe Environment Inspector**: Inspects non-sensitive configuration keys while strictly masking secrets (passwords, tokens, API keys) with 1 asterisk per character (`*` * strlen).
  - 🍌 **Nano Banana Status Easter Egg**: Bundled collapsible vintage movie poster *"Il Professore dei Server"* in `blog/app/assets/images/status_easter_egg_professor.png`.
- ⚠️ **Zero-Lag Educational Alert Banners in Workshop Alerts Hub**:
  - Added `_ephemeral_database.html.erb`: warns when running against local SQLite or local Postgres containers instead of Cloud SQL.
  - Added `_ephemeral_storage.html.erb`: warns when running on ephemeral local disk instead of GCS, explaining sad grayscale mode.
  - Added `_ai_status.html.erb`: warns when Nano Banana is operating in bundled fake cover fallback mode.
  - All banners feature a dedicated interactive **"Why? (Ask AI) 🤖"** explanation button.
- 🍌 **Dual AI Provider Support for Nano Banana (`blog/lib/nanobanana.rb`)**:
  - Added direct Google AI Studio support via `GEMINI_API_KEY` (`generativelanguage.googleapis.com`) alongside existing Vertex AI ADC authentication.
- 🧪 **Automated 8-Permutation UAT Suite**:
  - Added `blog/test/integration/nanobanana_uat_matrix_test.rb` and standalone CLI runner `blog/bin/uat_matrix_nanobanana.rb` validating all 8 combinations of (Local vs GCS) x (Working AI vs Fake AI) x (Uploaded vs Auto-generated).
- 📜 **Documentation**:
  - Created [`docs/WORKSHOP_TELEMETRY_AND_ALERTS.md`](file:///usr/local/google/home/ricc/git/rails8-app-on-gcp/docs/WORKSHOP_TELEMETRY_AND_ALERTS.md) detailing both functional and stylistic specifications.

## [0.1.36] - 2026-09-09
### Added
- 💳 **Workshop Slides**: Updated Slide 3 to "Reclaim Credits Now" with direct claim link button (`https://me.developers.google.com/benefits/claim/test-workshop-rails8`) and updated presentation outline.

## [0.1.35] - 2026-09-08
### Changed
- 👤 **Unified Google Cloud & Admin Identity (`GOOGLE_CLOUD_ACCOUNT` & `APP_ADMIN_PASSWORD`)**:
  - Established `GOOGLE_CLOUD_ACCOUNT` as the canonical identity variable across `.env.dist`, `seeds.rb`, diagnostics, and workshop documentation (replacing legacy `GCP_EMAIL`).
  - Standardized administrator password on `APP_ADMIN_PASSWORD` (with fallback to `ADMIN_PASSWORD`), documenting that admin email defaults directly to `GOOGLE_CLOUD_ACCOUNT`.
  - Added auto-discovery in `bin/workshop_diagnostics.rb` (`just workshop-test` / `just workshop-check`) to detect the active account from `gcloud auth list`.
  - Added explicit pre-flight warnings for non-Google accounts (`@gmail.com` or `@google.com`), alerting learners to critical dependencies on GCP Billable resources, Terraform apply (`user:email` IAM policy bindings), and Identity-Aware Proxy (IAP) single sign-on.
  - Added placeholder validation guarding against uncustomized `your-personal-email@gmail.com` in `.env` and `seeds.rb`.

## [0.1.34] - 2026-09-08
### Added
- 🌱 **Smart Seed Auto-Discovery & Narrative Storytelling Posts (Fixes [#25](https://github.com/palladius/rails8-app-on-gcp/issues/25))**:
  - Implemented environment & stage auto-discovery in `blog/db/seeds.rb` based on database adapter (SQLite vs Postgres), runtime platform (Cloud Run vs Localhost), and ActiveStorage service (Disk vs GCS).
  - Automatically seeds narrative posts tailored to the active stage:
    - **Stage 0 (Localhost)**: `[LOCAL BASELINE] Welcome to Rails 8 on Localhost!` with `local_sad_image.png` and Mailpit instructions.
    - **Stage 1 (Cloud Run Ephemeral)**: `[EPHEMERAL] ⚠️ Welcome to Cloud Run Single Container!` explaining container stateless resets.
    - **Stage 2 (Cloud Run GCS)**: `[GCS PERSISTENT] ☁️ ActiveStorage Connected to Cloud Storage` with `gcs_dev_image.jpg`.
    - **Stage 3 (Cloud SQL)**: `[CLOUD SQL PERSISTENT] 🐘 Connected to Google Cloud SQL!`.
  - Supports explicit override via `WORKSHOP_STEP=<N>` for automated graders.
  - Rewrote **Step 2: The Local Baseline, Mailpit & Admin Onboarding** in `workshop/CODELAB.md` to guide learners through Smart Seed, Mailpit, and interactive console debugging (relates to [#29](https://github.com/palladius/rails8-app-on-gcp/issues/29)).
### Changed
- 👤 **Unified GCP & Admin Identity (`GCP_EMAIL`)**:
  - Established `GCP_EMAIL` as the primary standard identity variable in `.env.dist` and across workshop tooling.
  - The Rails blog administrator account in `blog/db/seeds.rb` now defaults strictly to `GCP_EMAIL` (with fallback to `ADMIN_EMAIL`).
  - Added auto-discovery in `bin/workshop_diagnostics.rb` (`just workshop-test` / `just workshop-check`) to detect the logged-in Google account from `gcloud auth list` if omitted in `.env`.
  - Added explicit pre-flight warnings if a non-Google account (`@gmail.com` or `@google.com`) is configured, highlighting the critical dependencies on GCP Billable resources, Terraform apply (`user:email` IAM policy bindings), and Identity-Aware Proxy (IAP) single sign-on.

## [0.1.33] - 2026-09-08
### Changed
- 📘 **Codelab v2.0.0alpha: Header, Introduction, Step 0 & Step 1 Rewrite (Issue [#29](https://github.com/palladius/rails8-app-on-gcp/issues/29))**:
  - Upgraded `workshop/CODELAB.md` to `2.0.0alpha`, replacing legacy branch-based narratives with the canonical 8-Step and 3-Deploy architecture.
  - Rewrote **Step 0: Prerequisites, Antigravity Setup & Billing Verification** with mandatory billing guard gate check (`gcloud beta billing projects describe`), ADC setup, and instant validation (`just workshop-eval 0`).
  - Rewrote **Step 1: Terraform Infrastructure Kickoff & Pre-Flight Diagnostics** introducing pre-flight diagnostics (`just workshop-test`), fast isolated UAT testing (`just workshop-uat 1`), and asynchronous background Cloud SQL provisioning.
  - Verified compilation of static documentation site via `just build-ghpages`.

## [0.1.32] - 2026-09-08
### Added
- 🍌 **Nano Banana Auto-Cover Generation on Vertex AI (Fixes [#18](https://github.com/palladius/rails8-app-on-gcp/issues/18))**:
  - Added `blog/lib/nanobanana.rb`: builds the vintage 1960s Italian movie poster prompt from the post title + body (cameo banana, ruby gem shaped like an "8" top-right), falls back to a "Prog Metal in Modena" poster when the text is under 30 bytes or keyboard mash (`qwerty`), and calls `gemini-2.5-flash-image` on Vertex AI through `Net::HTTP` with Application Default Credentials only (no `GEMINI_API_KEY`, per #14).
  - `GenerateCoverImageJob` now really generates and attaches the cover, then broadcasts a Turbo refresh so the poster appears live on the post page.
  - **Localhost Invariant**: without project/ADC, on HTTP errors or timeouts, the job attaches the bundled `nanobanana_fake_cover.png` ("NO VERTEX AI CREDENTIALS — I'm a fake cover image. Pretend I'm real!") instead of failing.
  - **Asset provenance stamps** (Constitution §5) via libvips: covers stored on local disk are made grayscale with a little house / `127.0.0.1` stamp bottom-right; covers stored on GCS get a colorful cloud. User-uploaded covers get the same grayscale treatment as a CSS filter while on local disk and stay untouched on GCS (`cover_image_classes` helper).
  - Terraform (`iac/cloudrun.tf`): enables `aiplatform.googleapis.com`, grants `roles/aiplatform.user` to `rails-cloudrun-sa` and to every `developers` entry.
  - Tests: `test/lib/nanobanana_test.rb`, `test/jobs/generate_cover_image_job_test.rb`, `test/models/post_test.rb`, helper tests; a tiny `stub_singleton` test helper replaces `minitest/mock` (not shipped with minitest 6).
  - Conductor track `nanobanana_cover_issue_18_20260908`; workshop docs now describe Vertex AI + ADC, the fake fallback, and provenance stamps.
### Fixed
- 🐛 `GenerateCoverImageJob` called the non-existent `post.content` (guaranteed `NoMethodError`); it now uses `post.body.to_plain_text`.
- 🧪 The test environment used the real `google_test` GCS bucket; it now uses the local Disk service (`ACTIVE_STORAGE_SERVICE` overrides it), so `bin/rails test` runs offline in a few seconds.
- 🖼️ `bin/new_article.rb --image` attaches the cover **before** saving, so the CLI no longer enqueues a useless generation job that races the manual attachment.

## [0.1.31] - 2026-09-08
### Added
- 🧪 **Fast Isolated Workshop Step UAT Harness (`bin/workshop_uat.rb`)**:
  - Implemented an automated User Acceptance Testing (UAT) harness for validating workshop progression.
  - Automatically spins up a fresh, network-free local `git clone` in `/tmp`, replicates `.env`, applies Step N configuration (Time-Machine rewind or baseline), runs `bin/workshop_eval.rb <step>`, and tears down the sandbox cleanly.
  - Added recipe `just workshop-uat <step>` (defaults to Step 1). Enables lightning-fast validation of student onboarding without repetitive manual clones or branch switching.

## [0.1.30] - 2026-09-08
### Changed
- ⏳ **Consolidate Workshop Steps into Zero-Branch Time-Machine (Fixes [#28](https://github.com/palladius/rails8-app-on-gcp/issues/28))**:
  - Rescued and promoted legacy tests into the canonical test suite:
    - Added [`blog/test/config/storage_config_test.rb`](file:///usr/local/google/home/ricc/git/rails8-app-on-gcp/blog/test/config/storage_config_test.rb) guarding private IAM GCS signing and bucket namespacing.
    - Added [`blog/test/integration/cloud_run_configuration_test.rb`](file:///usr/local/google/home/ricc/git/rails8-app-on-gcp/blog/test/integration/cloud_run_configuration_test.rb) verifying multi-container sidecar compose configurations.
  - Implemented the Zero-Branch Time-Machine engine [`bin/workshop_time_machine.rb`](file:///usr/local/google/home/ricc/git/rails8-app-on-gcp/bin/workshop_time_machine.rb) and directory [`workshop/time-machine/`](file:///usr/local/google/home/ricc/git/rails8-app-on-gcp/workshop/time-machine/):
    - `workshop/time-machine/stage-1-stateless/`: pure SQLite and local Disk configuration overlays.
    - `workshop/time-machine/stage-2-gcs/`: GCS IAM signing with ephemeral SQLite configuration overlays.
  - Added convenient developer recipes in `justfile`: `just workshop-rewind <1|2>` and `just workshop-restore-gold`.
  - Completely removed obsolete legacy directory `workshop/steps/`.

## [0.1.29] - 2026-09-08
### Added
- 📐 **Declarative Workshop Skeleton & Hybrid/LLM Evaluation Engine (Fixes [#31](https://github.com/palladius/rails8-app-on-gcp/issues/31))**:
  - Created `workshop/skeleton.yaml` as the canonical, structured Single Source of Truth for the entire 8-step workshop roadmap.
  - Defined explicit schema per step: `title`, `description`, `pseudocode`, `prerequisites`, `postrequisites`, and heterogeneous `evals`.
  - Implemented `workshop/visualizer/build_skeleton.rb` compiler to render `workshop/SKELETON.md` deterministically from YAML.
  - Integrated `just build-skeleton` into `just build-ghpages` ensuring documentation consistency across CI and local visualizers.
  - Implemented `bin/workshop_eval.rb` evaluation engine executing `shell`, `ruby`, and `llm` evaluations (with structured JSON feedback contract `{return, comment, error_message}`).
  - Added recipe `just workshop-eval [step]` to validate student progress locally or via automated graders.

## [0.1.28] - 2026-09-08
### Added
- 🚨 **Workshop Unified Alerts Hub & Admin Bootstrap Guard (Fixes [#21](https://github.com/palladius/rails8-app-on-gcp/issues/21))**:
  - Unified all educational workshop UI banners under `blog/app/views/workshop/alerts/` (`_hub.html.erb`, `_missing_admin.html.erb`, `_stuck_jobs.html.erb`).
  - Added global flag `DISABLE_WORKSHOP_ALERTS=true` to easily disable all workshop warnings in production environments or when removing `app/views/workshop/`.
  - Added strict guard gate in `blog/db/seeds.rb` that aborts if `ADMIN_EMAIL` is missing or set to placeholder, enforcing explicit student identity setup.
  - Added educational "Notice: No administrator user found in database!" banner (`_missing_admin.html.erb`) with "Why? (Ask AI) 🤖" explainer modal when `User.count == 0`.
  - Added comprehensive integration tests in `blog/test/integration/missing_admin_warning_test.rb`.

## [0.1.27] - 2026-09-08
### Changed
- 🧹 **Workshop Documentation Reconciliation & Cleanup (Fixes [#27](https://github.com/palladius/rails8-app-on-gcp/issues/27))**:
  - Ratified `docs/CONSTITUTION.md` v1.1.0: formalizes the Zero-Branch Time-Machine progression model (`workshop/time-machine/`) alongside hierarchical git branch namespaces (`workshop/step-<N>-<slug>`).
  - Amalgamated `workshop/SKELETON.md` with the new canonical 8-Step master plan (3 Cloud Run deployments, pre-flight diagnostics, POLA stuck jobs warnings, GenAI pipelines, and capstone quests).
  - Preserved `workshop/app/SPEC.md` into `~/git/respec/docs/tools/workshop-visualizer/SPEC.md` and safely deleted obsolete stub `workshop/app/`.
  - Moved `workshop/IDEAS.md` to durable location `docs/ideas/WORKSHOP_IDEAS.md` and linked directly from `SKELETON.md`.
  - Removed obsolete draft `workshop/UNTOUCHABLE-CONSTITUTION.md` and redundant stub `workshop/USER_MANUAL.md`.
  - Isolated all visualizer and build engine code into dedicated subfolder `workshop/visualizer/` (`server.rb`, `build_ghpages.rb`), leaving `workshop/` lean and focused on curriculum content.
  - Updated `justfile`, CI workflow `.github/workflows/deploy-pages.yml`, `README.md`, and documentation to reflect the new `workshop/visualizer/` path.
  - Filed follow-up issue [#28](https://github.com/palladius/rails8-app-on-gcp/issues/28) to merge `workshop/steps/` into `workshop/time-machine/` and [#29](https://github.com/palladius/rails8-app-on-gcp/issues/29) to rewrite `workshop/CODELAB.md`.

## [0.1.26] - 2026-09-08
### Changed
- 🎨 **Workshop Visualizer Standardization (Fixes [#30](https://github.com/palladius/rails8-app-on-gcp/issues/30))**:
  - Selected the official Google Codelab (light/white) layout as the standard and sole workshop visualizer deployed to the root of GitHub Pages (`https://palladius.github.io/rails8-app-on-gcp/`).
  - Removed the prototype dark Astro/Glassmorphism SPA (`workshop/render-app2/`) and the codelab splitting script (`workshop/split_codelab.rb`).
  - Removed `/static/` routing from GitHub Pages deployment; static artifacts are now compiled directly into the root of `dist/` via `build_ghpages.rb`.
  - Updated `README.md`, `justfile`, `AGENTS.md`, `workshop/AGENTS.md`, and `docs/USER_MANUAL.md` to reference the single canonical build pipeline and official URL.
  - Polished `README.md` workshop section with direct links to Codelab, Constitution, and Skeleton, moving the preview screenshot under `assets/workshop_preview.png`.
  - Preserved a demo video of the dark theme sliding transition under `assets/demos/black_theme_transition.mp4` before retirement.
  - Hardened parallel test execution in `blog/test/integration/new_article_script_test.rb` using isolated temporary filenames.

## [0.1.25] - 2026-09-07
### Added
- 📊 **Workshop Kickoff Slides with Marp (Fixes [#20](https://github.com/palladius/rails8-app-on-gcp/issues/20))**:
  - Added `/slides/index.md` containing a clean, 6-step Marp presentation introducing attendees to downloading Google Antigravity, signing in, claiming cloud credits, launching the pair programming session, and closing with thanks and contact links.
  - Added `slides/README.md` with usage instructions for live presentation and static HTML/PDF exports.
  - Added `workshop/landing-page/README.md` (English primary) and `workshop/landing-page/README.it.md` (Italian companion) serving as the kickoff directive for Antigravity and workshop attendees.
  - Added `just slides [port]` (default `8082`), `just build-slides`, and `just test-slides` recipes to root `justfile` with automatic fallback to `npx` if global `marp` is not installed.
  - Added visual boundary regression test in `blog/test/integration/slides_presentation_test.rb` running Headless Chrome via Selenium to automatically verify that no slide overflows its 1280x720 viewport.
  - Fixed typography, line-height, and padding in `slides/index.md` to ensure all content (including callout boxes) renders cleanly without overflowing slide boundaries.
  - Added `/slides` endpoint to `workshop/server.rb` serving the compiled presentation deck directly.
  - Generated 3 distinctive cover art options via Nano Banana Pro (`slides/images/`): attached Pixar 3D style to Slide 1, preserved Retro Synthwave for future use, and attached Modern Minimalist Vector art to the final "Thank You!" closing slide (including LinkedIn contact links for Riccardo and Emiliano).
  - Added Google Cloud official SVG logomark to bottom-right of every slide via scoped Marp CSS.
  - Added circular face avatar badges of Riccardo and Emiliano to bottom-left of Slide 1 and Slide 6.
  - Replaced ASCII mockup on Slide 2/3 with real Google Antigravity "Sign into Google" screenshot (`slides/images/antigravity-login.png`).
  - Archived Slide 5 ("The Pedagogical Contract") to `slides/archive/pedagogical-contract.md` to keep the active presentation focused on the essential onboarding steps while preserving pedagogical instructions in `workshop/landing-page/README.md`.
  - Updated `.gitignore` to ignore compiled `slides/dist/` and `log/` artifacts.

## [0.1.24] - 2026-09-07
### Changed
- 📝 **Workshop ABOUT Page Overhaul**: Restructured `workshop/ABOUT.md` with a punchy title, Antigravity-powered abstract, and colorful Google-branded highlights linking Cloud Run Docker Compose, Solid Queue, IAP, Cloud SQL, and short-lived signed URLs.

## [0.1.23] - 2026-09-07
### Changed
- 🔓 **Unauthenticated Access for Public Posts**: Configured `PostsController` to allow unauthenticated access to `index` and `show` (`allow_unauthenticated_access only: %i[ index show ]`), allowing visitors and automated health/UAT probes to view public posts directly without redirecting to `/session/new`.
- 📦 Updated `.gcloudignore` to exclude local `worktrees/`, `blog/vendor/bundle/`, and `blog/storage/` from Cloud Build upload bundles.

## [0.1.22] - 2026-09-07
### Fixed
- 🐛 **ActionText Propshaft Missing Asset Handling (Fixes [#7](https://github.com/palladius/rails8-app-on-gcp/issues/7))**:
  - Overrode `app/views/action_text/attachables/_remote_image.html.erb` to catch `Propshaft::MissingAssetError` when an ActionText body contains relative/local file references (e.g. `../out/...` from pasted markdown or HTML) and gracefully fall back to `tag.img` with `.attachment__broken-image` class instead of crashing with HTTP 500.
  - Added `.attachment__broken-image` styling in `app/assets/stylesheets/actiontext.css` for clear visual indication of missing/unresolved assets.
  - Added defense-in-depth `rescue_from Propshaft::MissingAssetError` in `ApplicationController` returning HTTP 404 instead of an unhandled HTTP 500.
  - Added regression test suite in `test/controllers/posts_controller_test.rb`.

## [0.1.21] - 2026-09-07
### Changed
- 🗣️ Clarified **Language Directive** in `AGENTS.md` / `GEMINI.md`: AI agents must converse flexibly in the user's preferred language (e.g., Italian with Riccardo/Emiliano) while strictly authoring all repository resources, code, documentation, UI strings, and commits in English.

## [0.1.20] - 2026-09-07
### Changed
- 🔀 Merged remote `origin/main` (PR #15: Docker Compose refinements, Solid Queue production database alignment, and mailpit test fix).

## [0.1.19] - 2026-09-07
### Changed
- 📜 **Constitution v1.0.1 Ratification**: Cleaned and formalized [`docs/CONSTITUTION.md`](file:///usr/local/google/home/ricc/git/rails8-app-on-gcp/docs/CONSTITUTION.md), fixing numbering, incomplete sentences, and typos while establishing the 2/3 maintainer consensus rule (Riccardo, Emiliano, AI).
- 🌿 **Git Branch Naming Standard**: Reconciled workshop branch naming convention to use best-practice Git directory slashes `workshop/step-<N>-<slug>` (e.g. `workshop/step-1-local-baseline`), taking advantage of GitHub/GitLab collapsible tree views.
- ⚙️ **Localhost & Fast Test Invariants in `AGENTS.md`**: Embedded Constitutional Principle 6 into `AGENTS.md` / `GEMINI.md`, enforcing that the app runs on localhost at any time and automated tests fail fast (< 5s) with explicit diagnostic messages if external cloud services are offline.
- 🖼️ **Telemetry & Asset Provenance**: Added explicit requirements in `AGENTS.md` for visual asset watermarking ("local image" vs "GCS blob") and seed post origin tracking ("written by db:seed").
- 🏛️ **Document Hierarchy**: Explicitly structured hierarchy between the supreme meta-constitution (`docs/CONSTITUTION.md`), operational directives (`AGENTS.md`), and the workshop curriculum blueprint (`workshop/UNTOUCHABLE-CONSTITUTION.md`).

## [0.1.18] - 2026-09-07
### Changed
- 🌐 Standardized all app UI badges, runtime telemetry tooltips, and documentation strings to English as the primary language across `blog/`, `compose.yaml`, `.env.dist`, and `AGENTS.md`.
- 📜 Added **Language Directive (English First)** to `AGENTS.md` specifying English as the universal source of truth for global audiences with Italian as optional secondary flavor.

## [0.1.17] - 2026-09-07
### Changed
- 💅 Replaced `just dev` in badge labels and tooltip text with standard `Local Rails · SQLite` and `bin/dev` to avoid confusion for non-`just` users.

## [0.1.16] - 2026-09-07
### Changed
- 🐘 Configured `config/database.yml` in production so Solid Queue, Solid Cache, and Solid Cable inherit `DATABASE_URL` (or dedicated URL env vars) when running PostgreSQL on Cloud Run, preventing multi-container ephemeral SQLite isolation.
- ⚙️ Aligned database and user credentials in `compose.prod.yaml` with Terraform (`${DB_USER:-rails_user}` and `${DB_NAME:-rails_production}`).
- ✉️ Corrected service name (`worker`) and SMTP host (`mailpit`) in `blog/bin/test_email.sh`.
- 🧪 Added `DockerComposeConfigurationTest` to prevent regressions in local and production compose configurations.
### Added
- 🛡️ Implemented Anti-POLA runtime telemetry via `RAILS8_ENV_LAUNCH_MODE` environment variable and `ApplicationHelper#launch_mode_info`.
- 🎨 Added interactive runtime badge in the UI footer displaying distinct badges, colors, and explanatory tooltip stories:
  - 💻 `[💻 just dev · SQLite]` (`#6366f1`): *"Hello! I am the native app running with just dev on local SQLite."*
  - 🐳 `[🐳 Docker Compose · Postgres]` (`#0284c7`): *"Hello! I am the containerized app running with Docker Compose."*
  - ☁️ `[☁️ Google Cloud Run]` (`#059669`): *"Hello! I am running serverless on Google Cloud Run."*
- 🧪 Added full unit test suite for launch mode detection in `blog/test/helpers/application_helper_test.rb`.
- 📝 Documented `RAILS8_ENV_LAUNCH_MODE` in `.env.dist`, `blog/justfile`, `blog/compose.yaml`, `blog/compose.prod.yaml`, and `README.md`.

## [0.1.15] - 2026-09-07
### Changed
- 🧭 Consolidated all workshop views (`/`, `/constitution`, `/skeleton`, `/a2ui`) onto the single Workshop Sinatra server on port `8080`.
- 🧹 Removed obsolete `workshop-constitution` on port `8081` from `justfile` to eliminate port collision with Docker Compose Adminer (`:8081`).

## [0.1.14] - 2026-09-07
### Changed
- 🤖 Consolidated all AI guidelines and architectural directives from `GEMINI.md` into `AGENTS.md` as the single canonical source of truth for both Gemini and Claude Code.
- 🔗 Replaced `GEMINI.md` with an internal symlink pointing to `AGENTS.md`.

## [0.1.13] - 2026-09-07
### Changed
- 🔌 Changed default native Rails development port from `9090` to `8088` in `blog/justfile` and `README.md` to keep all local development ports cleanly aligned in the 808x family.

## [0.1.12] - 2026-09-07
### Added
- 📖 Documented the 3 startup modes (Native Rails app, Local Docker Compose stack, Workshop Codelab UI) and their complete 3x3 localhost port matrix in `README.md`.
- ⚡ Added `just compose-up`, `just compose-down`, and `just compose-logs` convenience recipes in root `justfile` and `blog/justfile`.

## [0.1.11] - 2026-09-07
### Added
- 💌 Added `UserMailer` with welcome email templates (HTML & text) triggered asynchronously upon user registration.
- 🧪 Added full integration test for welcome email delivery on signup in `blog/test/controllers/registrations_controller_test.rb`.
- 🪣 Added `gcs_local` service to `config/storage.yml` and `fake-gcs-server` emulator to `compose.yaml`.
- 📧 Added `blog/bin/test_email.sh` helper to verify local Mailpit delivery.
- 🚦 Integrated and completed Conductor track for Issue #10.

## [0.1.10] - 2026-08-28
### Added
- 👤 Added `description` and `created_via` columns to `User` model, tracking creation provenance (`"iap"`, `"seed"`, `"ui"`).
- 🛡️ Added `IAP_ALLOWED_USERS` comma-separated allowlist filtering with application-layer security in `IapAuthenticatable`.
- 📊 Added `just show-users` (and `just show-isers` alias) recipe rendering a clean CLI table of registered users ordered by `created_at DESC`.
- 🔔 Added instant UI notifications when authenticated or created via Google Cloud IAP.

### Changed
- 🧹 Debloated `.env.dist`: eliminated `ACTIVE_STORAGE_SERVICE`, `GCS_BUCKET_NAME`, and unused `SMTP_*` variables in favor of version-controlled, branch-friendly defaults.
- 📝 Standardized workshop step naming across documentation and configuration files.

## [0.1.9] - 2026-08-28

### Added
- 🛡️ Implemented Zero-Trust Google Cloud Identity-Aware Proxy (IAP) authentication concern (`IapAuthenticatable`) for automatic login on Cloud Run via `X-Goog-Authenticated-User-Email` with graceful localhost fallback.
- 📧 Added local Admin Email configuration (`ADMIN_EMAIL` & `ADMIN_PASSWORD`) in `seeds.rb` and `.env.dist`, dispatching password reset notifications to local Mailpit (port 8025).
- 🏗️ Added optional Google Cloud IAP module in Terraform (`iac/iap.tf`) with `enable_iap` and `iap_allowed_users` variables.
- 🧪 Added full integration test suite for IAP header authentication and user auto-creation (`blog/test/integration/iap_authentication_test.rb`).
- 🏆 Added **Step 8: Choose Your Own Adventure (The Quests)** to `CODELAB.md` and `SKELETON.md`.
- 🚦 Initialized Conductor track `admin_email_and_iap_auth_20260828`.

## [0.1.8] - 2026-08-26
### Added
- 🔀 Enhanced `workshop/server.rb` with a multi-document switcher supporting Codelab, Constitution, and Skeleton seamlessly.
- 📖 Created comprehensive User Manual & Extraction Architecture in `docs/USER_MANUAL.md` and `workshop/USER_MANUAL.md`.
- 🏗️ Upgraded `workshop/build_ghpages.rb` to statically compile `index.html`, `constitution.html`, and `skeleton.html`.
- ⚡ Added `just workshop-constitution` recipe to `justfile`.

## [0.1.7] - 2026-08-26
### Added
- 📜 Created `workshop/UNTOUCHABLE-CONSTITUTION.md` establishing the 4-part contract (`needs`, `does`, `wow`, `creates`) for all 8 workshop chapters.
- ✨ Embedded explicit **"Aha! / Wow Moments"** in every chapter (local rich-text drag-and-drop, live GCS upload, "Welcome to Cloud SQL" seeded post, multi-container instant boot, and NanoBanana AI cover generation).
- 💳 Added **Zero-Billing / Free Tier Track** alternative (Cloud Run SQLite mode + Gemini Free Tier API key, *ohne* Cloud SQL).
- ⏱️ Restructured workshop flow with asynchronous background Cloud SQL provisioning at start (Step 0) and baseline exploration during wait (Step 1).
- 🛡️ Restructured Step 3 into a two-part security journey: Phase 3A (naive `0.0.0.0/0` exposure anti-pattern) and Phase 3B (localhost Cloud SQL Auth Proxy via IAM credentials).
- 🐳 Added multi-container sidecar architecture (`web` + `worker` Solid Queue + `cloudsql-proxy`) in `workshop/CODELAB.md` and `workshop/SKELETON.md` inspired by Emiliano's GHI #10.
- ⏩ Marked Step 6 (CI/CD via Cloud Build) as **Optional / Skippable** to allow fast-tracking straight to AI features.
- 🛠️ Created `bin/provision-cloudsql.sh` helper script for 1-click async infrastructure provisioning.
- 🔄 Re-generated modular SPA pages under `workshop/render-app2/pages/` and rebuilt GitHub Pages static distribution.

## [0.1.6] - 2026-08-26
### Added
- 🔌 Clarified Google Antigravity setup (Option A: standalone IDE from https://antigravity.google/download; Option B: VS Code extension `Google.google-antigravity`) in the Setup & Prerequisites section in `workshop/CODELAB.md` and `workshop/SKELETON.md`.
- 🔄 Rebuilt static workshop pages and codelab distribution via `just build-ghpages`.

## [0.1.5] - 2026-08-24
### Changed
- 📝 Updated `workshop/CODELAB.md` to include default localhost credentials (`riccardo@example.com` / `Ch4ng3m3!!1`) for `bin/dev`.
- 🔗 Updated `workshop_url` in `blog/config/initializers/app_config.rb` footer link from `README.md` to `CODELAB.md`.

## [0.1.4] - 2026-08-21
### Added
- 🚀 Added a Ruby Sinatra-based Codelab Visualizer (`workshop/server.rb`) that splits `CODELAB.md` or any markdown file by H2 tags (`##`) and visualizes it as a Google Codelab experience with sidebar navigation, client-side step tracking, custom info-boxes, and Prism.js syntax highlighting.
- ⚙️ Integrated a new `just workshop-dev` recipe to quickly launch the Codelab visualizer on port 4567.
- 📦 Configured automatic user-space gem installation fallback inside the script to avoid corporate system-write permission issues.

## [0.1.3] - 2026-08-13
### Fixed
- 🐛 Fix 500 on every ActiveStorage blob on Cloud Run (issue #8) — `Google::Cloud::Storage::SignedUrlUnavailable: Service account credentials 'issuer (client_email)' is missing`. Cloud Run's metadata server has no private key, so `signed_url` could not sign; GCS services now sign through the IAM Credentials signBlob API (`iam: true` + `gsa_email` in `config/storage.yml`)
- 🔐 Buckets stay **private** — no `public: true`, no `allUsers` grant. URLs remain signed and expiring, as `iac/AGENTS.md` requires

### Added
- 🔑 Terraform: `roles/iam.serviceAccountTokenCreator` for the Cloud Run SA on itself, plus the `iamcredentials.googleapis.com` API — both required to sign blob URLs
- ✅ `blog/test/config/storage_config_test.rb` guards the GCS config against both regressions (signing without a key, and public buckets); it parses `storage.yml` directly, so it needs no booted app
- 🩺 `iac/check_gcp_setup.sh` now verifies the signing API and the token-creator binding
- 📖 Workshop: why the `public: true` shortcut is a trap (`CODELAB.md` step 2 + `SKELETON.md`)

### Changed
- 🧹 `config/storage.yml` derives the project id and signer SA once at the top instead of repeating the `ENV.fetch` six times. Override the signer with `GCS_SIGNER_SA_EMAIL`

## [0.1.2] - 2026-07-23
### Added
- 🎨 Post show page: glassmorphism card with hero image, styled title, meta line (updated at · comment count)
- 🔘 Post show actions: emoji buttons for Edit, Back, Destroy with confirmation dialog
- 👤 `User#display_name` helper (returns `name || email_address`)
- 🛣️ Added `/healthz` health-check route

### Fixed
- 🐛 Fix 500 error on `/posts/:id` — `simple_format` blew up on `ActionText::RichText` body; replaced with direct `<%= @post.body %>` rendering

### Changed
- 🧹 Flash notice on post show only renders when present (no empty `<p>` clutter)

## [0.1.1] - 2026-07-22
### Added
- 💎 Gemini-inspired blue-to-purple gradient background with glassmorphism UI
- 🔝 Sticky header nav bar with app logo, user badge (🧑‍💻 username), sign out
- 📊 Posts index: replaced ugly list with a clean table view
- ✏️❌ Inline action emojis (edit, delete with confirmation) per row
- 🦶 Footer with app name, version, Rails env, 📦 Code & 📖 Workshop links
- 🔗 Footer credits: "Made with [Ruby logo] love by Emiliano & Riccardo"
- ⚙️ Centralised app config (`config/initializers/app_config.rb`) for GitHub/Workshop URLs
- 🖼️ App logo (v1–v3) in header, linking to posts index

### Changed
- Posts table stripped to minimal `# | Title` — ID is clickable link to post
- Removed "New Post" from header nav (kept below table only)
- Removed Simple.css CDN (was conflicting with custom Gemini styles)
- Flash notice takes zero space when empty (conditional render)
- Eager loading for `cover_image` and `comments` to avoid N+1 queries

## [0.1.0] - 2026-07-21
### Added
- Initialized Conductor project workflow scaffolding.
- Defined Bifidus project vision (Rails 8 blueprint + Workshop).
- Updated `AGENTS.md` with explicit Google branding and incremental documentation instructions.
- Set up initial codebase framework in `blog/`.
