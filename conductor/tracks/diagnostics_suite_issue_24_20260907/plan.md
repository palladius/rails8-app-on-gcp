# Conductor Implementation Plan: Diagnostics Suite (`just workshop-test`)

> **Track ID:** `diagnostics_suite_issue_24_20260907`  
> **Status:** In Progress  

---

### Task 1: Create standalone executable script `bin/workshop_diagnostics.rb`
- [x] Parse `.env` file from root.
- [x] Check `ADMIN_EMAIL` (Error if empty, Warning if non-Gmail).
- [x] Check `GCP_PROJECT_ID` / `GOOGLE_CLOUD_PROJECT`.
- [x] Check active `gcloud` account login.
- [x] Check mandatory **GCP Billing Enabled** status via `gcloud beta billing projects describe`.
- [x] Check ADC access token for Vertex AI (`gcloud auth application-default print-access-token`).
- [x] Check Rails master key (`config/master.key` or env var).
- [x] Check GCS bucket and canary object (`seeds/gcs_dev_image.jpg`).
- [x] Check and display current state (`[🪫🪣]`, `[🪫☁️]`, or `[🔋☁️]`).
- [x] Make script executable (`chmod +x bin/workshop_diagnostics.rb`).

### Task 2: Wire `just workshop-test` into repository root `justfile`
- [x] Add recipe `workshop-test:` in `justfile`.
- [x] Run `just workshop-test` and verify formatted output and return code behavior.

### Task 3: Add automated unit test for diagnostics logic
- [x] Create a test script verifying that missing variables trigger expected exits and warnings (`test/test_workshop_diagnostics.rb`).
- [x] Verify execution passes (2 runs, 5 assertions, 0 failures).

### Task 4: Complete Track & Update GHI #24
- [x] Document usage in GHI #24.
- [x] Update conductor tracks registry.

