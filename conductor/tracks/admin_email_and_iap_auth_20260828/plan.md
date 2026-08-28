# Implementation Plan: Admin Email, Mailpit Onboarding & Zero-Trust Google Cloud IAP Auth

## Phase 1: Local Admin Email & Mailpit Onboarding (Step 1)
- [x] Task: Update `blog/db/seeds.rb` to read `ENV["ADMIN_EMAIL"]` and `ENV["ADMIN_PASSWORD"]`, and dispatch `PasswordsMailer.reset(user)`.
- [x] Task: Verify `.env.dist` includes `ADMIN_EMAIL` and `ADMIN_PASSWORD` documentation.
- [x] Task: Add test in `blog/test/models/user_test.rb` or seed test verifying password reset mailer dispatch.
- [ ] Task: Conductor - User Manual Verification 'Local Admin Email & Mailpit' (Protocol in workflow.md)

## Phase 2: Rails 8 IAP Zero-Trust Concern & Controller Tests
- [x] Task: Create `blog/app/controllers/concerns/iap_authenticatable.rb` extracting `X-Goog-Authenticated-User-Email` and starting session.
- [x] Task: Include `IapAuthenticatable` in `ApplicationController`.
- [x] Task: Add tests in `blog/test/controllers/sessions_controller_test.rb` verifying header authentication, user auto-creation, and local fallback.
- [ ] Task: Conductor - User Manual Verification 'Rails 8 IAP Concern' (Protocol in workflow.md)

## Phase 3: Terraform Infrastructure for Cloud IAP
- [x] Task: Add `enable_iap` and `iap_allowed_users` variables to `iac/variables.tf`.
- [x] Task: Create `iac/iap.tf` with Serverless NEG, Backend Service with IAP, HTTPS Target Proxy, and IAM bindings.
- [x] Task: Run `terraform validate` in `iac/`.
- [ ] Task: Conductor - User Manual Verification 'Terraform IAP Module' (Protocol in workflow.md)

## Phase 4: Workshop Documentation & Final Verification
- [x] Task: Verify `workshop/SKELETON.md` and `workshop/CODELAB.md` are in sync and reflect the Step 1 and Step 8 changes.
- [x] Task: Run `just test` to verify all Rails and architecture tests pass.
- [ ] Task: Conductor - User Manual Verification 'Final Verification' (Protocol in workflow.md)
