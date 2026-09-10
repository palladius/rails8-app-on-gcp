# Implementation Plan: Hardening Workshop Evaluations & Header Warning Mappings (Issue #85)

This plan implements semantic YAML parsing, negative testing, header warning test mapping, and 4 approved monotonic invariants.

---

## Phase 1: Header Workshop Alerts Integration Test Suite

- [x] Task: Create integration test for header alerts (Red Phase)
  - [x] Write `blog/test/integration/workshop_alerts_test.rb` asserting behavior of `_ephemeral_database`, `_ephemeral_storage`, and `_ai_status`.
- [x] Task: Verify integration test passes against baseline (Green Phase)
  - [x] Run `cd blog && bin/rails test test/integration/workshop_alerts_test.rb`.
- [x] Task: Phase 1 Verification & Checkpoint

---

## Phase 2: Semantic YAML Parsing & Invariant Engine Hardening

- [x] Task: Write failing unit tests for semantic parsing and new invariant handlers (Red Phase)
  - [x] Extend `test/test_workshop_invariants.rb` with tests for `compose_has_service` (using YAML), `no_local_storage` (using YAML), `three_tier_architecture`, `toolchain_integrity`, `database_migrations_current`, and `admin_user_seeded`.
- [x] Task: Implement semantic YAML parsing and new invariant handlers (Green Phase)
  - [x] Refactor `lib/workshop_eval/invariant_checker.rb` to use `YAML.safe_load`.
  - [x] Implement `check_three_tier_architecture` (verifies `web`, `worker`, `cloudsql-proxy`).
  - [x] Implement `check_toolchain_integrity` (ultra-fast PATH check for `git`, `gcloud`, `docker`, `terraform`, `ruby`, `just`).
  - [x] Implement `check_admin_user_seeded` (checks `User.where(admin: true).exists?` safely).
  - [x] Implement `check_database_migrations_current` (checks pending migrations safely when DB connected).
- [x] Task: Phase 2 Verification & Checkpoint

---

## Phase 3: Negative Regression Testing Suite

- [x] Task: Write negative regression tests in `test/test_workshop_invariants.rb`
  - [x] Assert broken compose files return `passed: false` with clear diagnostics.
  - [x] Assert `:local` storage returns `passed: false`.
  - [x] Assert stalled background jobs return `passed: false`.
- [x] Task: Test CLI exit code behavior
  - [x] Assert `bin/workshop_eval.rb` exits with code 1 when an invariant fails.
- [x] Task: Phase 3 Verification & Checkpoint

---

## Phase 4: Declarative Evals & Invariants in `workshop/skeleton.yaml`

- [x] Task: Update `workshop/skeleton.yaml` schema and step evals
  - [x] Add `inv-toolchain-integrity` (`from_step: 0`).
  - [x] Add `inv-database-migrations-current` (`from_step: 2`).
  - [x] Add `inv-admin-user-seeded` (`from_step: 2`).
  - [x] Add `inv-three-tier-architecture` (`from_step: 6`).
  - [x] Wire `workshop_alerts_test.rb` into step evaluations for Steps 2, 4, 6, and 7.
  - [x] Clean up permissive `|| true` flags in shell evals.
- [x] Task: Recompile visualizer documentation
  - [x] Run `ruby workshop/visualizer/build_skeleton.rb` and verify `workshop/SKELETON.md`.
- [x] Task: Phase 4 Verification & Checkpoint

---

## Phase 5: Verification, Versioning & Review

- [x] Task: Run full verification suite
  - [x] Run `just test`.
  - [x] Run `just workshop-eval all`.
- [x] Task: Version bump & documentation
  - [x] Update `VERSION` to `0.2.14`.
  - [x] Update `CHANGELOG.md` with Issue #85 summary.
- [x] Task: Phase 5 Verification & Final Review
