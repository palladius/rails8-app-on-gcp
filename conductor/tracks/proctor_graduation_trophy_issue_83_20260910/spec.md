# Specification: Proctor-Validated Step 8 Graduation Trophy via GHI & LGTM Verification

## Overview
Step 8 of the workshop is *"Choose Your Own Adventure / Advanced Quests"*. Because it is open-ended and non-deterministic, completion cannot be inferred from static server telemetry alone.
This feature establishes a **Proctor-Validated Proof-of-Work System** connecting:
1. **Student Cloud Run app (`blog/`)**: Parses `ENV['STEP_8_GHI']` and emits a structured `quest` payload in `/status.json`.
2. **The Hive Leaderboard Backend (`workshop/hive/`)**: Extends the existing Sinatra service with a `ProctorReviewer` component that checks GitHub Issue comments for an "LGTM" comment from an authorized proctor (`HIVE_PROCTORS`), with 120s caching and optional `GITHUB_TOKEN` support.
3. **The Hive Frontend (`workshop/hive/public/js/hive.js`)**: Visualizes graduation status:
   - If approved by proctor: Progress bar completes to **8/8 🏆** with purple/gold glowing effect, linking the trophy directly to the student's approved GitHub Issue.
   - If pending review: Progress bar shows **7/8** with an interactive badge: `⏳ GHI #XX pending proctor review` linking to the issue.
4. **Workshop Curriculum (`workshop/CODELAB.md`)**: Documents student graduation instructions at the conclusion of Step 8.

> **Note on Existing Codebase:** The Hive is already an active Sinatra service in `workshop/hive/` (with `app.rb`, `lib/healthchecker.rb`, and `public/js/hive.js`). This track surgically extends its existing telemetry and UI layers rather than recreating it.

---

## Functional Requirements

### 1. Rails Application (`blog/`)
- **Environment Variable**: `STEP_8_GHI` (accepts issue number `88` or full URL `https://github.com/palladius/rails8-app-on-gcp/issues/88`).
- **Telemetry Payload (`/status.json`)**:
  Add `quest` field:
  ```json
  "quest": {
    "step_8_completed": true,
    "ghi_issue": 88,
    "ghi_url": "https://github.com/palladius/rails8-app-on-gcp/issues/88"
  }
  ```
  If `STEP_8_GHI` is not set or invalid, `quest` reflects:
  ```json
  "quest": {
    "step_8_completed": false,
    "ghi_issue": null,
    "ghi_url": null
  }
  ```
- **Step Inference**: `workshop_step` retains auto-inferred baseline (step 7 when Cloud Run + Cloud SQL + GCS + AI are live), while `quest` provides proof-of-work telemetry for The Hive.
- **Controller & Tests**: Ensure `StatusesController` handles malformed or missing `STEP_8_GHI` gracefully without errors.
- **Environment Inspection**: Include `STEP_8_GHI` in `safe_env_inspection`.

### 2. The Hive Leaderboard Backend (`workshop/hive/`)
- **Configuration**:
  - `HIVE_PROCTORS`: comma-separated GitHub usernames (default: `"palladius,emilianodellacasa,ricc"`).
  - `GITHUB_TOKEN`: optional token for higher rate limits (5,000 req/hr vs 60 req/hr).
- **Proctor Reviewer Engine (`workshop/hive/lib/proctor_reviewer.rb`)**:
  - For each student with `telemetry.quest.ghi_issue`:
    - Queries `https://api.github.com/repos/palladius/rails8-app-on-gcp/issues/:id/comments`.
    - Scans comments for any comment where `user.login` is in `HIVE_PROCTORS` (case-insensitive) and `body` contains `"LGTM"` (case-insensitive regex: `/\bLGTM\b/i` or `LGTM` with emojis).
    - Caches verification results for 120 seconds per issue number in-memory.
    - Exposes state: `proctor_status: :lgtm_approved | :review_pending | :none` and `proctor_reviewer: "<login>"`.
- **Healthchecker Integration**: Include `quest` data and `proctor_review` status in the `/api/healthchecks` and `/api/leaderboard` responses.

### 3. The Hive Leaderboard Frontend (`workshop/hive/public/js/hive.js`)
- If `quest.ghi_issue` is present:
  - If approved (`proctor_status === 'lgtm_approved'`):
    - Progress bar displays `8/8` with purple/gold glowing bar and 8 filled segments.
    - The trophy 🏆 is an interactive link to `quest.ghi_url`, styled with tooltip `"Graduation Approved by @<reviewer>! Click to view Issue #XX"`.
  - If pending (`proctor_status === 'review_pending'`):
    - Progress bar displays `7/8`.
    - Render badge: `⏳ GHI #XX pending proctor review`, linking to `quest.ghi_url`.
- If no quest is present, existing 1-7 step rendering continues as normal.

### 4. Curriculum Documentation (`workshop/CODELAB.md`)
- Update Step 8 with graduation guide:
  1. Pick and complete a quest.
  2. Open a GitHub Issue titled `🎓 [Step 8 Completed] <Name>: <Quest>`.
  3. Update Cloud Run service: `gcloud run services update blog --update-env-vars STEP_8_GHI=<ISSUE_NUMBER>`.
  4. Ping proctors for review to unlock the 8/8 trophy on The Hive.

---

## Non-Functional Requirements
- **Resilience & Rate Limiting**: The Hive must never crash or hang if GitHub API is unreachable, rate-limited, or returns 404/403. Fallback gracefully to `:review_pending` or cached state.
- **Fast Telemetry (< 5ms)**: Rails status detection overhead must remain ~0 ms; parsing `STEP_8_GHI` is in-memory only.
- **Backwards Compatibility**: Existing students on Steps 1–7 without `STEP_8_GHI` continue to work without change.

---

## Acceptance Criteria
- [ ] `GET /status.json` in Rails returns `quest` object containing parsed `ghi_issue` and `ghi_url` when `STEP_8_GHI` is configured.
- [ ] Unit tests in Rails verify valid issue IDs, URLs, and edge cases (nil, empty string, non-numeric).
- [ ] Hive backend queries GitHub API comments safely and verifies proctor allowlist with case-insensitive "LGTM".
- [ ] Unit tests in Hive verify `ProctorReviewer` with mock responses (approved, pending, unapproved commenter, rate limit).
- [ ] Hive UI displays 8/8 trophy with issue link when approved, and 7/8 with pending badge when awaiting review.
- [ ] `workshop/CODELAB.md` includes clear graduation steps for students.

## Out of Scope
- Automatic GitHub webhook receivers (polling on Hive healthcheck is sufficient and stateless).
- Automated CI testing of student capstone code (manual proctor review is the intended design).
