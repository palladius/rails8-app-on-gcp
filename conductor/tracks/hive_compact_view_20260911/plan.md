# Implementation Plan: Workshop Hive Leaderboard High-Density 50+ Compact View

## Phase 1: Test Scaffold & HTML Toolbar Controls
- [x] Task: Write Tests for Compact Mode HTML Elements & Query Param Handling (8056b19)
  - [x] Add endpoint test in `test/test_api_leaderboard.rb` verifying index.html contains `#compact-view-btn` and compact mode container attributes
  - [x] Verify tests fail before implementation (Red phase)
- [x] Task: Implement Compact Mode Toggle Button & Header Toolbar in HTML (f362291)
  - [x] Update `workshop/hive/public/index.html` to add `#compact-view-btn` and `#compact-view-label` in the toolbar
  - [x] Ensure toolbar styling matches the existing Tailwind dark palette and dupe filter styling
  - [x] Run automated tests and verify green (Green phase)
- [x] Task: Phase 1 Verification & Checkpoint (Refer to workflow.md)

## Phase 2: JavaScript State Management & URL/Storage Synchronization
- [ ] Task: Implement Compact Mode State Engine in hive.js
  - [ ] Implement `isCompactMode()` checking `?compact=true`, `?compact=1`, `?density=compact`, and `localStorage('hive_compact_mode')`
  - [ ] Implement `toggleCompactMode()` updating `localStorage` and syncing `window.history.replaceState`
  - [ ] Implement `updateCompactViewUI()` updating button styling, icon, and label
- [ ] Task: Adapt Podium & Summary Headers for Compact Mode
  - [ ] Add compact mode responsive styling/class toggling for `#step8-podium-container` and stats cards to minimize vertical consumption
- [ ] Task: Phase 2 Verification & Checkpoint (Refer to workflow.md)

## Phase 3: Single-Line Row Rendering Engine & High-Density Verification
- [ ] Task: Implement Strict Single-Line Student Row Template
  - [ ] Implement compact branch in `renderTable()` for every student row
  - [ ] Ensure Status dot + latency ms render inline on the same line
  - [ ] Ensure HH:MM + truncated nickname + 8-step bar render strictly on 1 line
  - [ ] Ensure Cloud Run link + JSON link + Ruby/Rails version chips render strictly on 1 line with `whitespace-nowrap` and `overflow-hidden`
  - [ ] Reduce row height to `py-1` and text size to `text-[11px]` / `text-xs`
- [ ] Task: Verify 50-Student Screen Fit & Performance
  - [ ] Test with synthesized 50-student dataset to confirm all 50 rows fit without cell overflow or vertical row wrapping
  - [ ] Verify seamless transition when switching between Compact and Expanded mode
- [ ] Task: Phase 3 Verification & Checkpoint (Refer to workflow.md)

## Phase 4: Version Bump, Documentation & Final Verification
- [ ] Task: Version Bump and Changelog Update
  - [ ] Bump `workshop/hive/VERSION` from 0.1.3 to 0.1.4
  - [ ] Document High-Density Compact Mode (50+ students single-line view) in `workshop/hive/CHANGELOG.md`
- [ ] Task: Full Regression Suite Verification
  - [ ] Run all Hive test suites (`test_*.rb`)
  - [ ] Run blog `just test` suite
- [ ] Task: Phase 4 Verification & Checkpoint (Refer to workflow.md)
