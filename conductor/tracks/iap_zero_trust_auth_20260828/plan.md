# Implementation Plan: Zero-Trust Google Cloud Identity-Aware Proxy (IAP) Auth & Terraform Module

## Phase 1: Rails 8 IAP Concern & Controller Hook
- [ ] Task: Create `blog/app/controllers/concerns/iap_authenticatable.rb` extracting `X-Goog-Authenticated-User-Email` and establishing session.
- [ ] Task: Include `IapAuthenticatable` in `ApplicationController` before standard authentication checks.
- [ ] Task: Add test coverage in `blog/test/controllers/sessions_controller_test.rb` verifying both IAP header auto-login and regular password fallback.

## Phase 2: Terraform Module & Variables
- [ ] Task: Create `iac/iap.tf` with conditional `count = var.enable_iap ? 1 : 0` for Serverless NEG, Backend Service, HTTPS Proxy, URL Map, and Forwarding Rule.
- [ ] Task: Add `enable_iap` (default: `false`) and `iap_allowed_users` (default: `["riccardo@google.com", "emiliano@google.com"]`) in `iac/variables.tf`.
- [ ] Task: Add `google_iap_web_backend_service_iam_binding` for `roles/iap.httpsResourceAccessor`.

## Phase 3: Workshop Documentation (Quest 1)
- [ ] Task: Update `workshop/SKELETON.md` and `workshop/CODELAB.md` to feature IAP Zero-Trust as Quest 1 in Step 8.
- [ ] Task: Document how to test locally with `IAP_MOCK_EMAIL=me@gmail.com`.
