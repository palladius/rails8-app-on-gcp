# Changelog

All notable changes to this project will be documented in this file.
 
## [0.1.24] - 2026-09-07
### Added
- 📊 **Workshop Kickoff Slides with Marp (Fixes [#20](https://github.com/palladius/rails8-app-on-gcp/issues/20))**:
  - Added `/slides/index.md` containing a clean, 5-step Marp presentation introducing attendees to downloading Google Antigravity, signing in, claiming cloud credits, launching the pair programming session, and embracing the Socratic pedagogical contract ("Guide me, don't do everything for me").
  - Added `slides/README.md` with usage instructions for live presentation and static HTML/PDF exports.
  - Added `workshop/landing-page/README.md` (English primary) and `workshop/landing-page/README.it.md` (Italian companion) serving as the kickoff directive for Antigravity and workshop attendees.
  - Added `just slides [port]` (default `8082`), `just build-slides`, and `just test-slides` recipes to root `justfile` with automatic fallback to `npx` if global `marp` is not installed.
  - Added visual boundary regression test in `blog/test/integration/slides_presentation_test.rb` running Headless Chrome via Selenium to automatically verify that no slide overflows its 1280x720 viewport.
  - Fixed typography, line-height, and padding in `slides/index.md` to ensure all content (including callout boxes) renders cleanly without overflowing slide boundaries.
  - Added `/slides` endpoint to `workshop/server.rb` serving the compiled presentation deck directly.
  - Updated `.gitignore` to ignore compiled `slides/dist/` and `log/` artifacts.

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
