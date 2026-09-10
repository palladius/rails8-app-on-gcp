# Changelog

## [0.1.0] - 2026-09-10
### Added
- 🏆 **Proctor-Validated Proof-of-Work Verification (Issue #83)**:
  - Added `ProctorReviewer` module with GitHub API comments integration and `HIVE_PROCTORS` allowlist.
  - Added 120s in-memory caching to respect GitHub API rate limits.
  - Updated `Healthchecker` to evaluate `quest` telemetry from `/status.json` and automatically elevate approved students to Step 8.
  - Enhanced UI table in `public/js/hive.js` with glowing 8/8 trophy link and `⏳ GHI #XX review pending` badge.
