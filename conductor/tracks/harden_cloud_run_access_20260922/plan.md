# Implementation Plan: Harden Access to Cloud Run (Milestone 2)

## Phase 1: Documentation & Hardening Guide
- [ ] Task: Create `docs/HARDENING.md` with complete IAP, OAuth2, and Load Balancer setup instructions
- [ ] Task: Document `CLOUD_RUN_HARDENED` in `docs/ENV_VAR_NAMES.md` and `.env.dist`

## Phase 2: Application-Layer Warning Banner & Telemetry
- [ ] Task: Add `cloud_run_hardened?` helper method in Rails application
- [ ] Task: Render educational warning banner in `app/views/layouts/application.html.erb` when unhardened
- [ ] Task: Add controller/system tests for banner rendering and IAP detection

## Phase 3: Infrastructure & Terraform Alignment
- [ ] Task: Link `CLOUD_RUN_HARDENED` variable to Terraform `enable_iap` and `allow_unauthenticated`
- [ ] Task: Verify zero-trust ingress settings when hardened

## Phase 4: Verification & Milestone Review
- [ ] Task: Run full test suite (`just test`)
- [ ] Task: Verify banner appears only in unhardened mode
- [ ] Task: Document in `CHANGELOG.md`
