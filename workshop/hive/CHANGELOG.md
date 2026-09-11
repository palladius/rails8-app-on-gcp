# Changelog

## [0.1.3] - 2026-09-11
### Fixed & Improved
- 🏆 **Leaderboard Column Alignment & Fixed-Width Step Bars**:
  - Moved graduation trophy 🏆 (and pending ⏳ indicator) to the **left** of the student nickname (`HH:MM [🏆] [Nickname]`).
  - Implemented automatic cropping (`truncate` with ellipsis and full tooltip hover `title`) for long student nicknames, preventing row elongation.
  - Locked Student & Step column width (`w-72 min-w-[280px] max-w-[300px]`) in both table header and rows.
  - Fixed 8-segment progress bar dimensions to a strictly fixed `w-[98px]` pill with `shrink-0` bars, removing the internal trophy that previously caused Step 8 rows to expand and rob width from the stack telemetry column.
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
