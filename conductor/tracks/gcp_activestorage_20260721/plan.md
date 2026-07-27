# Implementation Plan: GCP ActiveStorage & Arch Setup

## Phase 1: Infrastructure as Code (GCP Resources) [35048e3]
- [x] Task: Initialize Terraform in `iac/` and define Google Cloud Foundation Fabric modules for GCS buckets (dev, test, prod).
- [x] Task: Define the Cloud Run Service Account and IAM permissions (Storage Object Admin on buckets) in Terraform.
- [x] Task: Define GCP Secret Manager resource for `RAILS_MASTER_KEY` and grant access to the Cloud Run Service Account in Terraform.
- [x] Task: Conductor - User Manual Verification 'Phase 1: Infrastructure as Code' (Protocol in workflow.md)

## Phase 2: ActiveStorage Configuration [a25421a]
- [x] Task: Review `rails8-turbo-chat-2026` for ActiveStorage configuration inspiration.
- [x] Task: Update `blog/config/storage.yml` to define GCS bucket mappings for development, test, and production.
- [x] Task: Update environment configuration files (`config/environments/*.rb`) to use the new GCS service.
- [x] Task: Conductor - User Manual Verification 'Phase 2: ActiveStorage Configuration' (Protocol in workflow.md)

## Phase 3: Validation & Stats Script
- [x] Task: Create `iac/check_gcp_setup.sh` (or ruby equivalent) script.
- [x] Task: Implement authentication (ADC), GCS bucket existence checks, and Secret Manager checks in the script.
- [x] Task: Implement media count fetching per `RAILS_ENV` (dev, test, prod) inside the script and format output.
- [x] Task: Conductor - User Manual Verification 'Phase 3: Validation & Stats Script' (Protocol in workflow.md)
## Phase 4: Thorough Testing and UAT Acceptance Plan
- [x] Task: Create TEST.md for 95% automated test plan and 5% manual steps.
- [x] Task: Review TEST.md with user and execute manual tests. [UAT passed 2026-07-27: Post#5 uploaded via GCSService ✅]
