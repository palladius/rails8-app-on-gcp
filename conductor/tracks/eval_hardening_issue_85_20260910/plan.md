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

- [ ] Task: Write failing unit tests for semantic parsing and new invariant handlers (Red Phase)
  - [ ] Extend `test/test_workshop_invariants.rb` with tests for `compose_has_service` (using YAML), `no_local_storage` (using YAML), `three_tier_architecture`, `toolchain_integrity`, `database_migrations_current`, and `admin_user_seeded`.
- [ ] Task: Implement semantic YAML parsing and new invariant handlers (Green Phase)
  - [ ] Refactor `lib/workshop_eval/invariant_checker.rb` to use `YAML.safe_load`.
  - [ ] Implement `check_three_tier_architecture` (verifies `web`, `worker`, `cloudsql-proxy`).
  - [ ] Implement `check_toolchain_integrity` (ultra-fast PATH check for `git`, `gcloud`, `docker`, `terraform`, `ruby`, `just`).
  - [ ] Implement `check_admin_user_seeded` (checks `User.where(admin: true).exists?` safely).
  - [ ] Implement `check_database_migrations_current` (checks pending migrations safely when DB connected).
- [ ] Task: Phase 2 Verification & Checkpoint

---

## Phase 3: Negative Regression Testing Suite

- [ ] Task: Write negative regression tests in `test/test_workshop_invariants.rb`
  - [ ] Assert broken compose files return `passed: false` with clear diagnostics.
  - [ ] Assert `:local` storage returns `passed: false`.
  - [ ] Assert stalled background jobs return `passed: false`.
- [ ] Task: Test CLI exit code behavior
  - [ ] Assert `bin/workshop_eval.rb` exits with code 1 when an invariant fails.
- [ ] Task: Phase 3 Verification & Checkpoint

---

## Phase 4: Declarative Evals & Invariants in `workshop/skeleton.yaml`

- [ ] Task: Update `workshop/skeleton.yaml` schema and step evals
  - [ ] Add `inv-toolchain-integrity` (`from_step: 0`).
  - [ ] Add `inv-database-migrations-current` (`from_step: 2`).
  - [ ] Add `inv-admin-user-seeded` (`from_step: 2`).
  - [ ] Add `inv-three-tier-architecture` (`from_step: 6`).
  - [ ] Wire `workshop_alerts_test.rb` into step evaluations for Steps 2, 4, 6, and 7.
  - [ ] Clean up permissive `|| true` flags in shell evals.
- [ ] Task: Recompile visualizer documentation
  - [ ] Run `ruby workshop/visualizer/build_skeleton.rb` and verify `workshop/SKELETON.md`.
- [ ] Task: Phase 4 Verification & Checkpoint

---

## Phase 5: Verification, Versioning & Review

- [ ] Task: Run full verification suite
  - [ ] Run `just test`.
  - [ ] Run `just workshop-eval all`.
- [ ] Task: Version bump & documentation
  - [ ] Update `VERSION` to `0.2.14`.
  - [ ] Update `CHANGELOG.md` with Issue #85 summary.
- [ ] Task: Phase 5 Verification & Final Review
