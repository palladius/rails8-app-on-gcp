# Implementation Plan: Merge workshop/steps into time-machine while preserving legacy test resources

## Phase 1: Rescue & Promote Legacy Tests to blog/test/
- [ ] Task: Promote `storage_config_test.rb` into `blog/test/config/storage_config_test.rb`
- [ ] Task: Promote `cloud_run_configuration_test.rb` into `blog/test/integration/cloud_run_configuration_test.rb`
- [ ] Task: Run `just test` to verify all promoted tests pass cleanly

## Phase 2: Build Zero-Branch Time-Machine Overlay Directory
- [ ] Task: Create `workshop/time-machine/stage-1-stateless/` with SQLite + local Disk storage configs
- [ ] Task: Create `workshop/time-machine/stage-2-gcs/` with SQLite + GCS IAM signing storage configs
- [ ] Task: Add helper script or recipes in `justfile` for `workshop-rewind` and `workshop-restore-gold`
- [ ] Task: Test rewind to stage 1, test rewind to stage 2, and test restore-gold

## Phase 3: Eradicate workshop/steps/ and Document
- [ ] Task: Remove `workshop/steps/` completely
- [ ] Task: Update `CHANGELOG.md` and `VERSION`
- [ ] Task: Verification gate via `just test`
