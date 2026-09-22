# Specification: Friction Log Telemetry & Data Structure (FL0–FL7)

## Track ID: `fl_telemetry_20260916`
- **Issue Reference:** [Issue #134](https://github.com/palladius/rails8-app-on-gcp/issues/134)
- **Target Branch:** `donotdelete/friction-log-data-structure` (immortalized, NEVER merged into `main`)

---

## 1. Overview & Context

This track establishes a formal telemetry data structure and an automated visualization suite for Friction Logs FL000 through FL007. Friction Logs document the end-to-end execution of the Rails 8 on GCP workshop by human and AI runners, tracking duration, step bottlenecks, blockers encountered, and code fixes.

This track will:
1. Define a clean, machine-readable dataset (`workshop/telemetry/friction_logs.yaml`) capturing all 8 Friction Logs (FL000 to FL007).
2. Record metadata, GHI links, PR links, exact start/end timestamps, explicit pause intervals (such as FL006 interrupted over Thu/Fri and resumed Mon morning), resolution times per step (0..8), error/warning counts, and dual Git commit provenance (app code SHA + workshop curriculum SHA and push timestamps).
3. Provide a Ruby data model and validation suite (`workshop/telemetry/friction_log.rb`).
4. Generate high-resolution SVG and PNG visualizations (Gantt timeline with pause markers, step-by-step resolution breakdowns, bug progression trends).
5. Implement an automated UAT test verifying the concurrency between FL006 and FL007, demonstrating their overlapping execution window, shared commit baseline, and dual PR outputs (#113 and #133).
6. Safeguard the branch `donotdelete/friction-log-data-structure` to ensure it remains a permanent reference branch and is never merged into `main`.

---

## 2. Functional Requirements

### FR-1: Declarative Telemetry Dataset (`workshop/telemetry/friction_logs.yaml`)
A comprehensive YAML file containing entries for `FL000` through `FL007` with the following attributes per entry:
- `id`: Unique identifier (`FL000` to `FL007`).
- `title`: Descriptive summary of the run.
- `runner`: Persona or agent executing the log (e.g. `palladius`, `antigravity-bot`).
- `account`: Google Cloud account used.
- `gcp_project_id`: Project ID provisioned.
- `ghi_url`: Canonical GitHub Issue URL.
- `pr_urls`: List of GitHub Pull Request URLs resulting from this run.
- `started_at`: ISO8601 UTC timestamp.
- `ended_at`: ISO8601 UTC timestamp.
- `pauses`: Array of pause intervals:
  - `started_at`: ISO8601 UTC timestamp.
  - `resumed_at`: ISO8601 UTC timestamp.
  - `reason`: Description of pause (e.g., weekend pause, waiting on quota/billing unsuspend).
- `active_duration_seconds`: Total active execution time excluding pauses.
- `wall_clock_duration_seconds`: Total elapsed time from `started_at` to `ended_at`.
- `steps`: Mapping for Steps 0 through 8:
  - `status`: `completed`, `skipped`, `failed`, or `partial`.
  - `duration_seconds`: Time spent on the step.
  - `errors_count`: Number of blockers/bugs hit.
  - `warnings_count`: Non-blocking frictions observed.
  - `notes`: Key observations or findings.
- `code_commit`:
  - `sha`: Git commit hash of the application codebase at test time.
  - `pushed_at`: Timestamp when the commit was pushed.
- `workshop_commit`:
  - `sha`: Git commit hash of the workshop content/codelab at test time.
  - `pushed_at`: Timestamp when the commit was pushed.
- `eval_score`: Final eval score (e.g. `69/69 ✅`).
- `bugs_found_count`: Total bug count recorded.
- `status`: Overall outcome (`success`, `blocked`, `abandoned`).

### FR-2: Ruby Data Model & Schema Validator (`workshop/telemetry/friction_log.rb`)
- Pure Ruby class providing data parsing, date/time calculation, and invariant assertions:
  - Invariant: `wall_clock_duration_seconds` >= `active_duration_seconds`.
  - Invariant: Sum of active step durations approximates active duration.
  - Validates ISO8601 timestamp integrity.
  - Invariant: Step indices 0..8 exist and adhere to status enums.
  - Validates Git commit SHAs (40-hex or 7-hex).

### FR-3: Visualizer Engine (`workshop/bin/render_fl_telemetry.rb`)
A Ruby CLI visualizer that reads `friction_logs.yaml` and produces:
1. `fl_gantt_timeline.svg` / `fl_gantt_timeline.png`: Multi-track Gantt timeline showing all runs, visually contrasting active working periods vs pause blocks.
2. `fl_concurrency_fl06_fl07.svg` / `fl_concurrency_fl06_fl07.png`: Focused concurrency diagram illustrating the overlap of FL006 and FL007 on Sept 11–16, 2026, and their dual PR generation.
3. `fl_step_durations.svg` / `fl_step_durations.png`: Stacked or clustered comparison of time spent per step (0..8) across iterations.
4. `fl_bugs_trend.svg` / `fl_bugs_trend.png`: Trend of bugs uncovered over time and categories.
5. `index.html`: Self-contained interactive report embedding all SVG/PNG artifacts and structured tables.

### FR-4: Concurrency UAT Verification (`test/workshop/fl_concurrency_uat_test.rb` & `workshop/bin/verify_fl_concurrency.rb`)
- Automated unit test & CLI script that checks:
  - Temporal overlap between FL006 active interval and FL007 active interval.
  - Code commit lineage verification (both branching off/sharing the v0.2.x baseline).
  - Validation of dual PR outputs (#113 and #133).

### FR-5: Remote Branch Isolation & Publication
- Immortalized branch: `donotdelete/friction-log-data-structure`.
- Must NEVER merge to `main`.
- Comments and image embeds posted to GHI #134.

---

## 3. Non-Functional Requirements
- **NFR-1: Zero External Gem Overhead:** Uses standard Ruby 3.4 standard libraries (`yaml`, `json`, `time`, `date`) and pure SVG vector generation.
- **NFR-2: CI & Local Safety:** Runs in < 2 seconds via `just test` or Ruby runner.
- **NFR-3: Immutable Main Guarantee:** Branch protection notice in `workshop/telemetry/README.md`.

---

## 4. Acceptance Criteria
- [ ] `workshop/telemetry/friction_logs.yaml` fully populated with FL000 through FL007.
- [ ] `workshop/telemetry/friction_log.rb` models and validates dataset cleanly.
- [ ] `test/workshop/friction_log_telemetry_test.rb` passes with 100% assertions.
- [ ] SVG and PNG charts generated in `workshop/telemetry/output/`.
- [ ] Concurrency UAT test passes for FL006 and FL007.
- [ ] Branch `donotdelete/friction-log-data-structure` pushed to remote.
- [ ] Visual telemetry report published to Issue #134.
