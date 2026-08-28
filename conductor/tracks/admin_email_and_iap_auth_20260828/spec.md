# Specification: Admin Email, Mailpit Onboarding & Zero-Trust Google Cloud IAP Auth

## Overview
Implement an end-to-end authentication and identity architecture for Rails 8 on GCP, connecting local developer onboarding to production cloud security:
1. **Local Baseline (Step 1)**: Configurable `ADMIN_EMAIL` in `.env` / `seeds.rb`, with password reset emails intercepted locally by Mailpit on port 8025 and interactive `rails console` password recovery workouts.
2. **Production Zero-Trust (Step 8 / Quest 1)**: Google Cloud Identity-Aware Proxy (IAP) integration via an External HTTPS Application Load Balancer in Terraform (`iac/iap.tf`), with automatic passwordless login in Rails via the `IapAuthenticatable` controller concern.

## Functional Requirements

### 1. Local Admin Email & Mailpit Onboarding (`seeds.rb`)
- Support environment variables:
  - `ADMIN_EMAIL`: Defaults to `"riccardo@example.com"`.
  - `ADMIN_PASSWORD`: Defaults to `"Ch4ng3m3!!1"`.
- `blog/db/seeds.rb` finds or creates the admin user with these credentials.
- On creation or seed run, dispatches `PasswordsMailer.reset(user).deliver_later`.
- Ensure ActionMailer in `development.rb` routes to Mailpit on `SMTP_HOST` / `SMTP_PORT` (1025) and UI is reachable on `http://localhost:8025`.

### 2. Rails 8 IAP Controller Concern (`IapAuthenticatable`)
- Create `blog/app/controllers/concerns/iap_authenticatable.rb`:
  - Intercepts `X-Goog-Authenticated-User-Email` on incoming HTTP requests.
  - Strips `accounts.google.com:` prefix to obtain the verified Google email.
  - Finds or creates a user with `SecureRandom.hex(16)` password.
  - Calls `start_new_session_for(user)` unless already authenticated.
- **Graceful Fallback**: If IAP headers are absent (localhost or direct Cloud Run without IAP), gracefully falls back to standard session & password authentication.
- **Local Simulation**: Supports `ENV["IAP_MOCK_EMAIL"]` for testing IAP flows on localhost.

### 3. Terraform Infrastructure for Cloud IAP (`iac/iap.tf` & `iac/variables.tf`)
- Add variable `enable_iap` (default: `false` to avoid unexpected Load Balancer idle costs).
- Add variable `iap_allowed_users` (default: `["ricc@google.com", "emiliano.dellacasa@gmail.com", "changeme@gmail.com"]`).
- When `enable_iap = true`:
  - Provision `google_compute_region_network_endpoint_group` (Serverless NEG pointing to Cloud Run).
  - Provision `google_compute_backend_service` with `iap` configuration.
  - Provision URL Map, HTTPS Target Proxy, Google-managed SSL Certificate, and Global Forwarding Rule.
  - Provision `google_iap_web_backend_service_iam_binding` granting `roles/iap.httpsResourceAccessor` to `var.iap_allowed_users`.

### 4. Workshop Documentation
- Update `workshop/SKELETON.md` and `workshop/CODELAB.md` to reflect the Mailpit local workout in Step 1 and the IAP Zero-Trust Quest in Step 8.

## Out of Scope
- Enforcing IAP on localhost.
- Automating OAuth Consent Screen creation in GCP projects where it requires manual Cloud Console configuration.
