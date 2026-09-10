# Specification: Cumulative Cascading Invariants for Workshop Steps (Issue #76)

## Overview & Origin

During the live verification of **Step 7: Generative AI Pipelines & Podcastifier** on a pristine GCP environment (Friction Log FL005 / Issue #76), UI screenshots revealed critical architectural regressions:
1. ⚠️ **Stuck Background Jobs Warning Banner visible**: A yellow alert banner declared `1 background job currently pending execution`, indicating a missing/stalled Solid Queue worker.
2. 💾 **Ephemeral Local Storage Badge visible**: The cover image stamp and footer badges declared `[EPHEMERAL LOCAL DISK]` instead of `[CLOUD PERSISTENT / GCS ☁️]`.

Despite these severe regressions, `bin/workshop_eval.rb 7` reported `4/4 PASSED ✅ (100% Green)` because the evaluation engine only evaluated isolated, step-local additions without enforcing monotonic architectural state progression ("one-way doors").

In a cloud workshop, architectural milestones are irreversible phase transitions:
- **From Step 4 onward**: Ephemeral local disk storage for media uploads must not be active (`:local` rejected; GCS mandatory).
- **From Step 6 onward**: Ephemeral SQLite production database must not be active (Cloud SQL mandatory), and background queue workers must actively drain jobs (zero stuck jobs permitted).

This track introduces first-class **Cumulative Cascading Invariants** into `workshop/skeleton.yaml` and `bin/workshop_eval.rb`, ensuring that when evaluating any step `N`, all invariants active for milestones up to `N` (`from_step <= N`) are strictly validated. It also adds a dedicated LLM-as-a-judge evaluation to Step 7 (`step-7-llm-clean-ui-no-warnings`) to ensure rendered UI/screenshots are completely free of warning banners.

---

## Functional Requirements

### 1. Declarative YAML Schema (`workshop/skeleton.yaml`)
Introduce a top-level `invariants:` list in `workshop/skeleton.yaml`. Each invariant specifies:
- `id` (string): Unique identifier (e.g., `inv-persistent-gcs-storage`).
- `from_step` (integer): The milestone step number from which this invariant becomes active and perpetually enforced.
- `title` (string): Short descriptive title.
- `description` (string): Pedagogical explanation of the invariant and why regressing is prohibited.
- `check` (string): Declarative rule identifier:
  - `no_local_storage`: Verifies that ActiveStorage configuration and runtime reject `:local` storage tier.
  - `zero_stuck_jobs`: Verifies that Solid Queue has 0 stalled or unassigned jobs in queue.
  - `compose_has_service`: Verifies that `compose.prod.yaml` includes required sidecar services (e.g. `cloudsql-proxy` or `worker`).
  - `ruby_code`: Custom Ruby predicate block as fallback.
- `params` (hash, optional): Declarative parameters passed to the check handler (e.g., `service: "cloudsql-proxy"`, `file: "blog/compose.prod.yaml"`).

Initial Invariants:
1. `inv-persistent-gcs-storage` (`from_step: 4`): From Step 4 onward, media storage cannot be `:local`; GCS (`:google_dev` or `:google_prod`) is mandatory.
2. `inv-zero-stuck-background-jobs` (`from_step: 6`): From Step 6 onward, Solid Queue worker sidecars must actively drain jobs.
3. `inv-cloud-sql-connected` (`from_step: 6`): From Step 6 onward, production deployment must include Cloud SQL Auth Proxy sidecar.

### 2. Step 7 Clean UI Evaluation (`step-7-llm-clean-ui-no-warnings`)
Add an LLM evaluation to Step 7 evals in `workshop/skeleton.yaml`:
- Evaluates that the rendered post view and UI screenshot are completely free of yellow warning banners, pending background jobs alerts, and ephemeral storage badges.

### 3. Ruby Invariant Engine (`bin/workshop_eval.rb` & `lib/workshop_eval/`)
- Implement an idiomatic, modular Ruby invariant checker class (`WorkshopEval::InvariantChecker`).
- Evaluates declarative rules cleanly via dispatch / pattern matching.
- Evaluates cumulative invariants when a step `N` is targeted:
  - Collects all invariants with `from_step <= N`.
  - Executes them under a dedicated visual section with distinct status badges:
    ```text
    🛡️  Verifying Cumulative Invariants (Active for Steps 1 -> 7):
       - [INV: Step 4+] GCS Persistent Storage Invariant... PASSED ✅
       - [INV: Step 6+] Zero Stuck Jobs Invariant... PASSED ✅
       - [INV: Step 6+] Cloud SQL Production Persistence Invariant... PASSED ✅
    ```
- When `bin/workshop_eval.rb all` is executed, cumulative invariants are executed per step or summarized across all steps.
- In case of failure, emits a prominent **REGRESSION ALERT** explaining the violated invariant milestone and remediation guidance.

### 4. Visualizer & Tooling Compatibility
- Update `workshop/visualizer/build_skeleton.rb` to render a new "Cumulative Workshop Invariants" section in `workshop/SKELETON.md`.
- Ensure `workshop/screenshots/runner.js` regex parser cleanly ignores or supports the `invariants:` block without breaking screenshot discovery.

---

## Non-Functional Requirements
- **Localhost Invariant & Offline Resilience (< 5s):** All invariant checks must execute in milliseconds without making blocking network requests to live GCP APIs. If remote backing services are offline, static inspection or safe fallback mode must be used.
- **TDD:** Automated unit tests in `test/test_workshop_invariants.rb` and schema validation in `test/test_workshop_skeleton.rb`.
- **Code Style:** Pure, idiomatic Ruby 3.4 matching carlessian ruby-coding standards.

---

## Acceptance Criteria
- [ ] `workshop/skeleton.yaml` contains valid `invariants:` block with the 3 milestone invariants.
- [ ] Step 7 in `workshop/skeleton.yaml` contains `step-7-llm-clean-ui-no-warnings`.
- [ ] `bin/workshop_eval.rb 3` does NOT execute Step 4+ or Step 6+ invariants.
- [ ] `bin/workshop_eval.rb 7` DOES execute Step 4+ and Step 6+ invariants.
- [ ] `workshop/visualizer/build_skeleton.rb` generates clean `SKELETON.md` including the invariants table.
- [ ] `node workshop/screenshots/runner.js --dry-run` and `ruby test/test_workshop_screenshots.rb` pass without error.
- [ ] Complete test suite (`just test`, `ruby test/test_workshop_invariants.rb`, `ruby test/test_workshop_skeleton.rb`) passes 100% green.

---

## Out of Scope
- Mandatory live internet connection during local offline evaluations.
- Modifying workshop time-machine rewind mechanisms or steps 0-8 application code beyond invariant validation.
