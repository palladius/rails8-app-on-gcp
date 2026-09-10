# Specification: Hardening Workshop Evaluations & Header Warning Mappings (Issue #85)

## Overview & Origin

Following the introduction of cumulative cascading invariants in PR #84 (Issue #76), this track hardens the workshop evaluation engine (`workshop/skeleton.yaml`, `bin/workshop_eval.rb`, and `lib/workshop_eval/invariant_checker.rb`).

Specifically, this track addresses the critical feedback from Riccardo:
1. **Header Warning Test Mapping**: Map all educational warnings rendered in the application header (`blog/app/views/workshop/alerts/` via `_hub.html.erb`) to dedicated integration tests and corresponding step evaluations/invariants:
   - **SQL** (`_ephemeral_database`): Active on SQLite/local Postgres; suppressed when Google Cloud SQL is connected.
   - **Storage** (`_ephemeral_storage`): Active on `:local` disk; suppressed from Step 4 onward when GCS is active.
   - **AI** (`_ai_status`): Active in fallback mode when credentials are missing; suppressed when live Gemini / Vertex AI is configured.
   - **Docker 1 vs 3 Containers** (`_stuck_jobs`): Active in single-container deployment when background jobs accumulate; suppressed in 3-container sidecar deployment when workers drain queue.
   - **Admin** (`_missing_admin`): Active when database has 0 users; suppressed once seeded.
2. **Approved Additional Invariants**:
   - `inv-admin-user-seeded` (`from_step: 2`): Verifies database has at least 1 bootstrapped admin user.
   - `inv-three-tier-architecture` (`from_step: 6`): Semantic YAML verification of `compose.prod.yaml` asserting `web`, `worker`, and `cloudsql-proxy`.
   - `inv-toolchain-integrity` (`from_step: 0`): Ultra-fast (< 20ms) check verifying essential CLIs (`git`, `gcloud`, `docker`, `terraform`, `ruby >= 3.3`, `just`).
   - `inv-database-migrations-current` (`from_step: 2`): Fast check verifying 0 pending migrations if DB is connected (safely skipped if offline).
   - *(Note: Git secrets check explicitly excluded to avoid brittleness inside Docker images and Cloud Run).*
3. **Semantic YAML Parsing over String Grepping**:
   - Replace brittle `.include?` checks in `InvariantChecker` with `YAML.safe_load` for `compose.prod.yaml` and `storage.yml`.
4. **Negative Regression Testing**:
   - Automated tests in `test/test_workshop_invariants.rb` proving that broken configs trigger `passed: false`, actionable diagnostics, and exit code `1`.
5. **Permissive Crutches Removal**:
   - Clean up `|| true` in shell evals (`step-3-shell-cloudrun-service`, `step-5-shell-secrets-exist`).

---

## Functional Requirements

### 1. Integration Tests for Header Workshop Alerts
Create `blog/test/integration/workshop_alerts_test.rb` covering the unmapped header alerts:
- **`_ephemeral_database.html.erb`**:
  - Asserts `.workshop-ephemeral-database-alert` is rendered when running against SQLite/local Postgres without Cloud SQL env vars.
  - Asserts alert is NOT rendered when `CLOUDSQL_INSTANCE` or Cloud SQL `DATABASE_URL` is set.
- **`_ephemeral_storage.html.erb`**:
  - Asserts `.workshop-ephemeral-storage-alert` is rendered when `storage_tier == :local`.
  - Asserts alert is NOT rendered when `storage_tier == :gcs`.
- **`_ai_status.html.erb`**:
  - Asserts `.workshop-ai-fallback-alert` is rendered when `Nanobanana.available? == false`.
  - Asserts alert is NOT rendered when `Nanobanana.available? == true`.

### 2. Semantic YAML Invariant Checker (`lib/workshop_eval/invariant_checker.rb`)
- Refactor `check_compose_has_service` to parse `compose.prod.yaml` via `YAML.safe_load` and inspect `services[target_service]`.
- Refactor `check_no_local_storage` to parse `config/storage.yml` via `YAML.safe_load` and verify google/GCS provider definition.
- Add handler `check_three_tier_architecture`: parses `compose.prod.yaml` and asserts presence of `web`, `worker`, and `cloudsql-proxy`.
- Add handler `check_toolchain_integrity`: fast PATH check using `system("which ...")` for `git`, `gcloud`, `docker`, `terraform`, `ruby`, `just`.
- Add handler `check_admin_user_seeded`: checks `User.where(admin: true).exists?` when DB is connected.
- Add handler `check_database_migrations_current`: checks pending migrations safely via `ActiveRecord::MigrationContext`.

### 3. Declarative Invariants & Evaluations (`workshop/skeleton.yaml`)
Update `workshop/skeleton.yaml` with the approved new invariants:
- `inv-toolchain-integrity` (`from_step: 0`)
- `inv-database-migrations-current` (`from_step: 2`)
- `inv-admin-user-seeded` (`from_step: 2`)
- `inv-three-tier-architecture` (`from_step: 6`)
- Link `blog/test/integration/workshop_alerts_test.rb` into step evals for Step 2, Step 4, Step 6, and Step 7.
- Clean up `|| true` from shell commands in Step 3 and Step 5.

### 4. Negative Regression Testing Suite (`test/test_workshop_invariants.rb`)
- Add test cases using temporary/mocked configurations:
  - Missing service in compose YAML -> `passed: false`, clear error message.
  - `:local` storage tier -> `passed: false`.
  - Stalled background jobs -> `passed: false`.
- End-to-end test verifying `bin/workshop_eval.rb` exits with status `1` when an invariant fails.

---

## Non-Functional Requirements
- **Execution Speed (< 5s)**: Invariant evaluation must remain well under the 5-second limit, with toolchain and database checks completing in milliseconds.
- **Docker / Cloud Run Safety**: Zero assumptions about `.git` presence; safe rescues around ActiveRecord when database is uninitialized or offline.
- **TDD**: Write failing tests before modifying implementation code.

---

## Acceptance Criteria
- [ ] `blog/test/integration/workshop_alerts_test.rb` created and passing all tests for SQL, Storage, and AI alerts.
- [ ] `lib/workshop_eval/invariant_checker.rb` parses YAML semantically.
- [ ] `workshop/skeleton.yaml` includes the 4 new approved invariants (`inv-toolchain-integrity`, `inv-database-migrations-current`, `inv-admin-user-seeded`, `inv-three-tier-architecture`).
- [ ] `test/test_workshop_invariants.rb` includes negative regression tests and passes.
- [ ] `just test` passes 100% green.
- [ ] `just workshop-eval all` passes cleanly with all cumulative invariants active.
- [ ] Visualizer documentation (`workshop/SKELETON.md`) updated.
