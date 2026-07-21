# Implementation Plan: GCP ActiveStorage & Arch Setup

## Phase 1: Infrastructure as Code (GCP Resources)
- [~] Task: Initialize Terraform in `iac/` and define Google Cloud Foundation Fabric modules for GCS buckets (dev, test, prod).
- [ ] Task: Define the Cloud Run Service Account and IAM permissions (Storage Object Admin on buckets) in Terraform.
- [ ] Task: Define GCP Secret Manager resource for `RAILS_MASTER_KEY` and grant access to the Cloud Run Service Account in Terraform.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Infrastructure as Code' (Protocol in workflow.md)

## Phase 2: ActiveStorage Configuration
- [ ] Task: Review `rails8-turbo-chat-2026` for ActiveStorage configuration inspiration.
- [ ] Task: Update `blog/config/storage.yml` to define GCS bucket mappings for development, test, and production.
- [ ] Task: Update environment configuration files (`config/environments/*.rb`) to use the new GCS service.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: ActiveStorage Configuration' (Protocol in workflow.md)

## Phase 3: Validation & Stats Script
- [ ] Task: Create `iac/check_gcp_setup.sh` (or ruby equivalent) script.
- [ ] Task: Implement authentication (ADC), GCS bucket existence checks, and Secret Manager checks in the script.
- [ ] Task: Implement media count fetching per `RAILS_ENV` (dev, test, prod) inside the script and format output.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Validation & Stats Script' (Protocol in workflow.md)
