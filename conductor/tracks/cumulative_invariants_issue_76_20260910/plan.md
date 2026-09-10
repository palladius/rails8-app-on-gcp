# Implementation Plan: Cumulative Cascading Invariants for Workshop Steps (Issue #76)

## Phase 1: Test Suite & Declarative Schema (TDD Foundation)

- [x] Task: Write unit tests for cumulative invariants schema and runner logic (72286db)
  - [x] Update `test/test_workshop_skeleton.rb` to assert that `workshop/skeleton.yaml` contains `invariants` list with required fields (`id`, `from_step`, `title`, `description`, `check`)
  - [x] Create `test/test_workshop_invariants.rb` with tests covering invariant step filtering (`from_step <= N`), execution isolation, and regression alert triggering
  - [x] Verify that new tests fail initially (TDD Red phase)
- [x] Task: Extend `workshop/skeleton.yaml` with declarative invariants and Step 7 LLM eval (eba5e7c)
  - [x] Define root-level `invariants:` list in `workshop/skeleton.yaml`
  - [x] Add `inv-persistent-gcs-storage` (`from_step: 4`, `check: no_local_storage`)
  - [x] Add `inv-zero-stuck-background-jobs` (`from_step: 6`, `check: zero_stuck_jobs`)
  - [x] Add `inv-cloud-sql-connected` (`from_step: 6`, `check: compose_has_service`, params: `service: cloudsql-proxy`)
  - [x] Add `step-7-llm-clean-ui-no-warnings` to Step 7 `evals:` list
  - [x] Verify `test/test_workshop_skeleton.rb` passes (TDD Green phase)
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 2: Ruby Invariant Engine Implementation (`bin/workshop_eval.rb`)

- [x] Task: Implement the Invariant Engine with an elegant, idiomatic Ruby design (3427b55)
  - [x] Create `lib/workshop_eval/invariant_checker.rb` implementing modular rule evaluation for `no_local_storage`, `zero_stuck_jobs`, `compose_has_service`, and `ruby_code`
  - [x] Ensure non-blocking offline resilience and fast timeouts (< 5s) adhering to `docs/CONSTITUTION.md`
  - [x] Update `bin/workshop_eval.rb` to load invariants and evaluate all active invariants where `from_step <= current_step_number`
  - [x] Implement colorized visual formatting with `🛡️  Verifying Cumulative Invariants (Active for Steps 1 -> N):` and `[INV: Step X+]` badges
  - [x] Add regression alert emission upon invariant failure with clear diagnostic explanations
  - [x] Run `test/test_workshop_invariants.rb` and verify all tests pass
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 3: Visualizer, Tooling & End-to-End Verification

- [x] Task: Update visualizer compiler and verify tooling compatibility (b3381fe)
  - [x] Update `workshop/visualizer/build_skeleton.rb` to render Cumulative Invariants in `workshop/SKELETON.md`
  - [x] Execute `just build-skeleton` and inspect generated `workshop/SKELETON.md`
  - [x] Verify `node workshop/screenshots/runner.js --dry-run` and `ruby test/test_workshop_screenshots.rb` pass cleanly
- [x] Task: Full verification gate across the workshop (70ecb52)
  - [x] Run `bin/workshop_eval.rb 3` and verify Step 4+ and Step 6+ invariants do not run
  - [x] Run `bin/workshop_eval.rb 7` and verify Step 4+ and Step 6+ invariants run and pass alongside the clean UI eval
  - [x] Run `bin/workshop_eval.rb all` and verify full workshop evaluation
  - [x] Run root `just test` (Rails test suite + ArchSpec) and all unit tests in `test/`
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md)
