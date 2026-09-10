# Implementation Plan: Proctor-Validated Step 8 Graduation Trophy via GHI & LGTM Verification

## Phase 1: Rails Telemetry (`StatusesController` & `STEP_8_GHI` Quest Object) [checkpoint: 6d2a649]
- [x] Task: Write failing tests for `STEP_8_GHI` in `blog/test/controllers/statuses_controller_test.rb` (TDD Red) [6d5ea91]
    - [x] Add test for `STEP_8_GHI="83"` emitting integer `83` and canonical issue URL
    - [x] Add test for `STEP_8_GHI="https://github.com/palladius/rails8-app-on-gcp/issues/83"` parsing correctly
    - [x] Add test for missing / nil `STEP_8_GHI` emitting `step_8_completed: false`
    - [x] Confirm tests fail (Red)
- [x] Task: Implement `detect_quest_status` in `blog/app/controllers/statuses_controller.rb` (TDD Green) [1221e91]
    - [x] Parse `ENV['STEP_8_GHI']` for integer ID or regex match against github issue URL
    - [x] Expose `quest` object in `/status.json` with `step_8_completed`, `ghi_issue`, `ghi_url`
    - [x] Add `STEP_8_GHI` to `safe_env_inspection` list
    - [x] Confirm all controller tests pass (Green)
- [x] Task: Phase 1 Verification & Checkpoint (Refer to workflow.md) [6d2a649]

## Phase 2: Hive Backend Proctor Reviewer Engine (`workshop/hive/`)
- [~] Task: Write unit tests for `ProctorReviewer` in `workshop/hive/test/test_proctor_reviewer.rb` (TDD Red)
    - [ ] Test proctor comment with "LGTM" returns `:lgtm_approved` and reviewer username
    - [ ] Test non-proctor comment with "LGTM" returns `:review_pending`
    - [ ] Test missing LGTM comment returns `:review_pending`
    - [ ] Test GitHub API timeout or rate limit falls back gracefully to `:review_pending`
    - [ ] Test in-memory 120s TTL caching
    - [ ] Confirm tests fail (Red)
- [ ] Task: Implement `ProctorReviewer` in `workshop/hive/lib/proctor_reviewer.rb` (TDD Green)
    - [ ] Parse `HIVE_PROCTORS` (default: `"palladius,emilianodellacasa,ricc"`)
    - [ ] Build GitHub API comment fetcher using `Net::HTTP` with optional `GITHUB_TOKEN`
    - [ ] Match case-insensitive `\bLGTM\b` from approved proctors
    - [ ] Add in-memory thread-safe cache with 120s expiration
    - [ ] Confirm `test_proctor_reviewer.rb` passes (Green)
- [ ] Task: Integrate `ProctorReviewer` into `workshop/hive/lib/healthchecker.rb`
    - [ ] Extract `quest` metadata from `/status.json`
    - [ ] When `ghi_issue` is present, invoke `ProctorReviewer.review(ghi_issue)`
    - [ ] Expose `quest` and `proctor_status` in telemetry payload
    - [ ] Update existing `test_healthchecker.rb` and `test_api_leaderboard.rb`
- [ ] Task: Phase 2 Verification & Checkpoint (Refer to workflow.md)

## Phase 3: Hive Frontend Visualization (`workshop/hive/public/js/hive.js`)
- [ ] Task: Update Hive student row rendering in `workshop/hive/public/js/hive.js`
    - [ ] Check `quest` telemetry and `proctor_status`
    - [ ] When `lgtm_approved`: render progress bar as `8/8` with purple/gold glowing bar and clickable trophy 🏆 linking to `quest.ghi_url`
    - [ ] When `review_pending`: render progress bar as `7/8` with a badge `⏳ GHI #XX pending proctor review` linking to `quest.ghi_url`
    - [ ] Ensure non-quest students render steps 1–7 normally
- [ ] Task: Phase 3 Verification & Checkpoint (Refer to workflow.md)

## Phase 4: Workshop Curriculum & Codelab Instructions (`workshop/CODELAB.md`)
- [ ] Task: Document Step 8 graduation flow in `workshop/CODELAB.md`
    - [ ] Explain how to complete a quest and submit a GitHub issue with title `🎓 [Step 8 Completed] <Name>: <Quest>`
    - [ ] Explain how to configure `STEP_8_GHI` on Cloud Run via `gcloud run services update`
    - [ ] Explain how proctors review and comment LGTM to unlock the 8/8 trophy on The Hive
- [ ] Task: Rebuild Codelab HTML via `ruby workshop/visualizer/build_ghpages.rb`
- [ ] Task: Phase 4 Verification & Checkpoint (Refer to workflow.md)

## Phase 5: End-to-End Verification & Quality Gate
- [ ] Task: Run full automated test suites (`cd blog && bin/rails test`, `cd workshop/hive && bundle exec rake test`)
- [ ] Task: Run `just test` (per project standard)
- [ ] Task: Update `VERSION` and `CHANGELOG.md`
- [ ] Task: Phase 5 Verification & Checkpoint (Refer to workflow.md)
