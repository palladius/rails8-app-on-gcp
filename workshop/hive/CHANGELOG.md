# Changelog

## [0.1.5] - 2026-09-11
### Fixed
- 🐞 **Client-Side Compact Scope Fix**:
  - Scoped `const compact = isCompactMode()` properly at top of `renderTable()` in `public/js/hive.js`.
  - Fixed client-side rendering exception when loading cached or live telemetry.

## [0.1.4] - 2026-09-11
### Added & Improved
- 📐 **High-Density 50+ Compact View (Issue #47 / Single-Line Row Mode)**:
  - Added dedicated **Compact Mode** (`View: Compact (50+)` / `View: Full`) toggle button in the Hive header toolbar with `localStorage` persistence.
  - Added URL query parameter support (`?compact=true`, `?compact=1`, or `?density=compact`) with automatic `window.history.replaceState` synchronization.
  - Implemented strict **Single-Line Student Rows** (`whitespace-nowrap`, row height `30px`, `py-1`):
    - Status Dot (🟢/🔴) with latency in ms inline.
    - `HH:MM` timestamp, student nickname (truncated with hover tooltip), and medals/trophies.
    - 8-segment progress bar.
    - Cloud Run direct link with service logo.
    - Raw `/status.json` endpoint direct link.
    - Ruby & Rails version chips, Rails environment badge (`prod`/`dev`), and GCP Triad indicators (`🐘 ☁️ 🍌`).
    - Posts count and Cloud Run revision tag.
  - Adapted Step 8 Champions Podium to a low-profile slim strip in compact mode, maximizing vertical screen real estate for 50+ students on a single screen without scrolling.
  - Added automated layout verification in `test/verify_compact_50_students.mjs`.

## [0.1.3] - 2026-09-11
### Fixed & Improved
- 🏆 **Step 8 Champions Podium & Ranked Medals (Issue #89 / Hall of Fame)**:
  - Added dedicated **Step 8 Champions Podium** strip above the table, ranking finishers chronologically by timestamp of victory (`won_at`).
  - Added ranked medal badges to the left of the student nickname: `🥇` (1st place), `🥈` (2nd place), `🥉` (3rd place), and `🏆` (subsequent finishers) with rich hover tooltips.
  - Added pulsating `⏳` review-pending indicator for quest submissions awaiting proctor approval.
  - Added `step_8_podium` array to JSON endpoints (`/index.json`, `/status.json`, `/metastatus.json`).
- 📐 **Rigid `table-fixed` Layout & Zero-Overlap Column Isolation**:
  - Converted table to `table-fixed` with explicit widths (`w-14` for status, `w-[440px]` for Student & Step, `w-auto` for App URL & Metrics) to give nicknames ample breathing room while strictly preventing cells from overflowing.
  - Applied `truncate block` with full `title` tooltip to student nicknames, ensuring long names never push the progress bar.
  - Locked 8-segment progress bar dimensions to a strictly fixed `w-[96px]` pill with `shrink-0` bars, removing internal trophies.
  - Replaced `break-all` on Cloud Run URLs with `truncate max-w-full` to eliminate multi-line URL wrapping.
  - Added automatic `gh auth token` fallback in `ProctorReviewer` when `GITHUB_TOKEN` is unset.

## [0.1.2] - 2026-09-11
### Added
- 🍯 **Comprehensive JSON Endpoints (`/index.json`, `/status.json`, `/metastatus.json`)**:
  - Implemented `GET /index.json`, `GET /status.json`, and `GET /metastatus.json` endpoints returning the aggregated student array with direct links to their Cloud Run app (`url`), status JSON (`status_url`), and up healthcheck (`up_url`).
  - Added HTTP content negotiation on `GET /` returning JSON when `Accept: application/json` header is sent.
  - Added query string parameter persistence (`query_params: params`) and event metadata tracking (`event_name`, `event_start`, `elapsed_minutes`, `cinderella_hours_remaining`).
  - Added comprehensive unit tests in `test_api_leaderboard.rb`.

## [0.1.1] - 2026-09-11
### Fixed & Added
- 🐝 **Duplicate Cloud Run URL Deduplication & Toggle**:
  - Implemented `deduplicate_by_url` and `normalize_url` in `SheetsReader` to take the second (last / latest) submission when duplicate Cloud Run URLs exist by default.
  - Added `show_duplicates=true` (and typo-tolerant `show_duplicatees_true`) support in `GET /api/leaderboard` to opt out of deduplication.
  - Added interactive duplicate toggle pill (`👯 Dupes: Off/ON`) in `public/index.html` and `public/js/hive.js`.
  - Added URL normalization handling whitespace, case-insensitivity, trailing slash stripping, and protocol scheme handling for `.run.app` domains.
  - Added unit test coverage in `test_sheets_reader.rb` and `test_api_leaderboard.rb`.

## [0.1.0] - 2026-09-10
### Added
- 🏆 **Proctor-Validated Proof-of-Work Verification (Issue #83)**:
  - Added `ProctorReviewer` module with GitHub API comments integration and `HIVE_PROCTORS` allowlist.
  - Added 120s in-memory caching to respect GitHub API rate limits.
  - Updated `Healthchecker` to evaluate `quest` telemetry from `/status.json` and automatically elevate approved students to Step 8.
  - Enhanced UI table in `public/js/hive.js` with glowing 8/8 trophy link and `⏳ GHI #XX review pending` badge.
