# 📊 Friction Log Telemetry & Data Structure Suite (FL000–FL007)

> ⚠️ **SUPREME BRANCH SAFETY NOTICE:**
> **DO NOT MERGE THIS BRANCH TO `main`!**
> This branch (`donotdelete/friction-log-data-structure`) is an **immortalized telemetry and retrospective reference branch**.
> It preserves the complete experimental data models, concurrency validators, and visual telemetry charts for FL000 through FL007 without polluting `main`.

---

## 🎯 Purpose

This directory contains the canonical telemetry dataset, models, visualizers, and concurrency UAT verification suite for all workshop test iterations (Friction Logs FL000 through FL007).

It tracks:
1. **Metadata & Provenance:** Issue links, PR links, runner accounts, GCP projects, and dual commit provenance (Code SHA vs Workshop Curriculum SHA + push timestamps).
2. **Timestamps & Pauses:** Exact ISO8601 start/end timestamps and explicit pause intervals (such as FL006's Thu/Fri pause and Mon morning resumption).
3. **Granular Step Metrics:** Per-step duration, status, error count, and warning count across Steps 0 through 8.
4. **Concurrency Validation:** Automated verification that FL006 and FL007 executed concurrently from an identical starting ancestor commit (`4a2f81a`), producing parallel PRs (#113 and #133).

---

## 📁 Directory Structure

- `friction_logs.yaml`: Primary machine-readable source of truth for FL000–FL007.
- `friction_log.rb`: Ruby PORO data model and schema validator with duration and invariant assertions.
- `visualizer.rb`: Pure Ruby vector engine rendering multi-track Gantt timeline, step durations, concurrency overlap, and bug trends into SVG, PNG, and HTML.
- `output/`:
  - `fl_gantt_timeline.svg` / `fl_gantt_timeline.png`
  - `fl_concurrency_fl06_fl07.svg` / `fl_concurrency_fl06_fl07.png`
  - `fl_step_durations.svg` / `fl_step_durations.png`
  - `fl_bugs_trend.svg` / `fl_bugs_trend.png`
  - `index.html`: Self-contained dashboard embedding charts and master scorecard.

---

## 🛠️ Commands & Verification

### 1. Run Unit & UAT Tests
```bash
ruby test/test_friction_log_telemetry.rb
ruby test/test_friction_log_visualizer.rb
ruby test/test_fl_concurrency_uat.rb
```

### 2. Regenerate All Visualizations (SVG + PNG + HTML)
```bash
ruby workshop/bin/render_fl_telemetry.rb
```

### 3. Verify Concurrency UAT (FL006 vs FL007)
```bash
ruby workshop/bin/verify_fl_concurrency.rb
```

---

## 🔗 Related Issues & Pull Requests

- **Issue #95:** [Friction Log Retrospective: FL001–FL006 Analysis, Metrics & Action Items](https://github.com/palladius/rails8-app-on-gcp/issues/95)
- **Issue #132:** [fix: FL007 blockers and pin Ruby 3.4.5](https://github.com/palladius/rails8-app-on-gcp/issues/132)
- **Issue #134:** [📊 Friction Log Telemetry & Data Structure (FL0–FL7 Timeline, Metrics & Visualizations)](https://github.com/palladius/rails8-app-on-gcp/issues/134)
- **PR #99 / #109 / #113:** FL006 Bug Fixes & Improvements
- **PR #130 / #133:** FL007 Bug Fixes & Improvements
