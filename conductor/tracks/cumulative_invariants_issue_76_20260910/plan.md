# Implementation Plan: Cumulative Cascading Invariants for Workshop Steps (Issue #76)

## Phase 1: Test Suite & Declarative Schema (TDD Foundation)

- [x] Task: Write unit tests for cumulative invariants schema and runner logic (72286db)
  - [x] Update `test/test_workshop_skeleton.rb` to assert that `workshop/skeleton.yaml` contains `invariants` list with required fields (`id`, `from_step`, `title`, `description`, `check`)
  - [x] Create `test/test_workshop_invariants.rb` with tests covering invariant step filtering (`from_step <= N`), execution isolation, and regression alert triggering
  - [x] Verify that new tests fail initially (TDD Red phase)
- [ ] Task: Extend `workshop/skeleton.yaml` with declarative invariants and Step 7 LLM eval
  - [ ] Define root-level `invariants:` list in `workshop/skeleton.yaml`
  - [ ] Add `inv-persistent-gcs-storage` (`from_step: 4`, `check: no_local_storage`)
  - [ ] Add `inv-zero-stuck-background-jobs` (`from_step: 6`, `check: zero_stuck_jobs`)
  - [ ] Add `inv-cloud-sql-connected` (`from_step: 6`, `check: compose_has_service`, params: `service: cloudsql-proxy`)
  - [ ] Add `step-7-llm-clean-ui-no-warnings` to Step 7 `evals:` list
  - [ ] Verify `test/test_workshop_skeleton.rb` passes (TDD Green phase)
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 2: Ruby Invariant Engine Implementation (`bin/workshop_eval.rb`)

- [ ] Task: Implement the Invariant Engine with an elegant, idiomatic Ruby design
  - [ ] Create `lib/workshop_eval/invariant_checker.rb` implementing modular rule evaluation for `no_local_storage`, `zero_stuck_jobs`, `compose_has_service`, and `ruby_code`
  - [ ] Ensure non-blocking offline resilience and fast timeouts (< 5s) adhering to `docs/CONSTITUTION.md`
  - [ ] Update `bin/workshop_eval.rb` to load invariants and evaluate all active invariants where `from_step <= current_step_number`
  - [ ] Implement colorized visual formatting with `🛡️  Verifying Cumulative Invariants (Active for Steps 1 -> N):` and `[INV: Step X+]` badges
  - [ ] Add regression alert emission upon invariant failure with clear diagnostic explanations
  - [ ] Run `test/test_workshop_invariants.rb` and verify all tests pass
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 3: Visualizer, Tooling & End-to-End Verification

- [ ] Task: Update visualizer compiler and verify tooling compatibility
  - [ ] Update `workshop/visualizer/build_skeleton.rb` to render Cumulative Invariants in `workshop/SKELETON.md`
  - [ ] Execute `just build-skeleton` and inspect generated `workshop/SKELETON.md`
  - [ ] Verify `node workshop/screenshots/runner.js --dry-run` and `ruby test/test_workshop_screenshots.rb` pass cleanly
- [ ] Task: Full verification gate across the workshop
  - [ ] Run `bin/workshop_eval.rb 3` and verify Step 4+ and Step 6+ invariants do not run
  - [ ] Run `bin/workshop_eval.rb 7` and verify Step 4+ and Step 6+ invariants run and pass alongside the clean UI eval
  - [ ] Run `bin/workshop_eval.rb all` and verify full workshop evaluation
  - [ ] Run root `just test` (Rails test suite + ArchSpec) and all unit tests in `test/`
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)
