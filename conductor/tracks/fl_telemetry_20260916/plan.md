# Implementation Plan: Friction Log Telemetry & Data Structure (FL0–FL7)

Track ID: `fl_telemetry_20260916`
Source of Truth: `conductor/tracks/fl_telemetry_20260916/spec.md`

## Phase 1: Telemetry Data Model & Dataset Foundation
- [x] Task 1.1: Write failing unit tests for Friction Log schema and validator (Red Phase) [11ae16e]
    - [x] Create `test/test_friction_log_telemetry.rb` asserting validation rules, timestamp parsing, step enumeration (0..8), and pause calculations.
- [x] Task 1.2: Implement Friction Log parser and validator model (Green Phase) [ec28c89]
    - [x] Create `workshop/telemetry/friction_log.rb` with schema attributes, timestamp validators, duration helpers, and consistency invariants.
- [x] Task 1.3: Compile and seed comprehensive telemetry dataset for FL000 through FL007 [ec28c89]
    - [x] Create `workshop/telemetry/friction_logs.yaml` capturing real data for FL000–FL007 (links, timestamps, pauses, step durations, errors, commit SHAs).
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md) [ec28c89]

## Phase 2: Visualizer Engine & Multi-Chart Generation
- [x] Task 2.1: Write failing tests for SVG and Chart generators (Red Phase) [bb832d0]
    - [x] Create `test/test_friction_log_visualizer.rb` verifying SVG structure, Gantt timeline bars, pause shading, and step duration math.
- [~] Task 2.2: Implement Ruby visualizer script (Green Phase)
    - [ ] Create `workshop/bin/render_fl_telemetry.rb` generating multi-track Gantt timeline, FL006/FL007 concurrency chart, step durations stacked chart, and bug trend chart.
- [ ] Task 2.3: Generate SVG & PNG chart artifacts and self-contained HTML dashboard
    - [ ] Output artifacts to `workshop/telemetry/output/` and render `index.html`.
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 3: UAT Concurrency Validation (FL006 vs FL007)
- [ ] Task 3.1: Write UAT test asserting temporal overlap and dual PR generation between FL006 and FL007 (Red Phase)
    - [ ] Create `test/workshop/fl_concurrency_uat_test.rb` asserting overlap of FL006 and FL007 runs and shared codebase ancestor commit.
- [ ] Task 3.2: Implement dedicated concurrency inspector script and visual output (Green Phase)
    - [ ] Create `workshop/bin/verify_fl_concurrency.rb` displaying detailed execution overlap, delta, and PR provenance.
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 4: Remote Branch Immortalization & Artifact Publication
- [ ] Task 4.1: Establish safety guard documentation in `workshop/telemetry/README.md` declaring branch immortalization (`donotdelete/friction-log-data-structure`) and preventing merge to `main`.
- [ ] Task 4.2: Rename / push branch `donotdelete/friction-log-data-structure` to remote `origin`.
- [ ] Task 4.3: Post comprehensive summary with generated charts and metrics to GHI #134 and open draft PR.
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)
