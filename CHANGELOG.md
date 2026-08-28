# Changelog

All notable changes to this project will be documented in this file.
 
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
