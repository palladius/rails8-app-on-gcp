# Changelog

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
