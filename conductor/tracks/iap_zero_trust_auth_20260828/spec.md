# Specification: Zero-Trust Google Cloud Identity-Aware Proxy (IAP) Auth & Terraform Module

## Overview
Implement optional Zero-Trust authentication using Google Cloud Identity-Aware Proxy (IAP) with an External HTTPS Application Load Balancer in front of Cloud Run, alongside native Rails 8 header authentication.

This eliminates password friction for verified Google / Google Workspace identities, while preserving clean local development fallback and zero cost for default setups (`enable_iap = false`).

## Functional Requirements

### 1. Terraform Infrastructure (`iac/iap.tf`)
- Provide an optional IAP module controlled by `variable "enable_iap" { default = false }`.
- When enabled (`enable_iap = true`):
  - Provision Serverless Network Endpoint Group (NEG) pointing to the Rails Cloud Run service.
  - Provision Backend Service with IAP enabled (`google_compute_backend_service` with `iap` block).
  - Provision URL Map, Target HTTPS Proxy, Google-managed SSL Certificate, and Global Forwarding Rule.
  - Configure IAM bindings on the IAP backend service granting `roles/iap.httpsResourceAccessor` to `var.iap_allowed_users` (e.g., `["riccardo@google.com", "emiliano@google.com"]`).

### 2. Rails 8 Integration (`blog/app/controllers/concerns/iap_authenticatable.rb`)
- Check for incoming IAP headers on all authenticated routes:
  - `X-Goog-Authenticated-User-Email` (format: `accounts.google.com:user@gmail.com`).
  - (Optional verification) `X-Goog-IAP-JWT-Assertion`.
- Auto-find or create the user in PostgreSQL based on the verified email.
- Establish an active Rails session automatically without requiring password entry.
- **Graceful Fallback**: If IAP headers are missing (e.g., `localhost:3000` or direct Cloud Run URL when IAP is disabled), cleanly fall back to standard Rails 8 session & password auth.

### 3. Developer & Workshop Experience
- Add `IAP_MOCK_EMAIL` support in `development.rb` for optional local testing of IAP flows.
- Document the feature as **Quest 1 (Zero-Trust IAP)** in Step 8 of the workshop.

## Out of Scope
- Enforcing IAP on localhost.
- Automatic creation of OAuth Consent Screen (must be created manually or pre-existing in GCP project).
