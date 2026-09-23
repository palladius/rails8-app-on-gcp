# Specification: Harden Access to Cloud Run (Milestone 2: Post-Modena)

## Overview
This track introduces a togglable, secure Cloud Run deployment mode to eliminate the `allUsers` security anti-pattern while maintaining zero-friction learning during workshops. It provides an explicit toggle (`CLOUD_RUN_HARDENED`), a UI warning banner when unhardened, and links to `HARDENING.md`.

## Target Milestone
**Milestone 2 (Post-Modena):** Planned for post-conference delivery. Not to be merged prior to the Modena workshop.

## Functional Requirements
1. **Toggle Variable (`CLOUD_RUN_HARDENED`):**
   - Boolean flag in `.env` and `iac/variables.tf`.
   - Default: `false` (Unhardened/Workshop Mode) for minimal friction.
   - When `true`: restricts Cloud Run ingress, enables Identity-Aware Proxy (IAP) via Application Load Balancer (`iac/iap.tf`), and verifies `X-Goog-Authenticated-User-Email`.
2. **Unhardened Mode Detection & Warning Banner:**
   - If `CLOUD_RUN_HARDENED != true` in production/staging environments, the Rails blog displays an educational warning banner in the UI:
     > ⚠️ **Warning:** This deployment is publicly accessible to the entire internet without IAP protection! To harden your production environment, follow the zero-trust guide in `HARDENING.md`.
   - The banner includes a direct link to `HARDENING.md` and `skills/rails8app-workshop`.
3. **Hardening Guide Documentation (`docs/HARDENING.md`):**
   - Detailed step-by-step instructions on setting up OAuth consent, IAP credentials, SSL certificate, and enabling `enable_iap = true`.

## Acceptance Criteria
- [ ] `CLOUD_RUN_HARDENED` toggle works seamlessly in both Rails application logic and Terraform.
- [ ] Educational warning banner displays prominently when running unhardened on Cloud Run.
- [ ] Warning banner links directly to `docs/HARDENING.md`.
- [ ] No regressions in existing test suite (`just test`).
