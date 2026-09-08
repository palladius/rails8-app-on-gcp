# Implementation Plan: Rewrite CODELAB.md to v2.0.0alpha

## Phase 1: Foundation, Step 0 & Step 1 Rewrite
- [x] Task: Update `workshop/CODELAB.md` frontmatter & intro to v2.0.0alpha (aligned with Constitution v1.1.0 and skeleton.yaml)
- [x] Task: Rewrite **Step 0: Prerequisites, Antigravity Setup & Billing Verification** (clear gcloud auth, ADC, billing gate check)
- [x] Task: Rewrite **Step 1: Terraform Infrastructure Kickoff & Pre-Flight Diagnostics** (pre-flight diagnostics `just workshop-test`, background Cloud SQL provisioning)
- [x] Task: Verify build pipeline: run `just build-ghpages` to compile `workshop/build/index.html` without errors
- [x] Task: Phase Verification & Checkpoint (Verify rendered codelab preview)
