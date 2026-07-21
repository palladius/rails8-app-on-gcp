# Specification: GCP ActiveStorage & Arch Setup

## Overview
Implement the Google Cloud Storage (GCS) setup and foundational GCP architecture for the `rails8-app-on-gcp` project. This includes infrastructure-as-code for bucket provisioning, Service Accounts, Secret Manager integration, and a validation script.

## Functional Requirements
1. **Infrastructure as Code (Terraform / gcloud)**:
   - Create configurations in `iac/` using **Google Cloud Foundation Fabric** modules where appropriate.
   - Provision three dedicated GCS buckets (dev, test, prod) in a European region.
   - **Service Account**: Create a dedicated GCP Service Account for Cloud Run. Grant it appropriate IAM permissions (e.g., `roles/storage.objectAdmin`) to access the GCS buckets.
   - **Secret Manager**: Provision a secret in GCP Secret Manager to hold the `RAILS_MASTER_KEY`. Grant the Cloud Run Service Account `roles/secretmanager.secretAccessor` on this secret.

2. **Validation & Stats Script**:
   - Create a checking script (e.g., `bin/check_gcp_setup`).
   - Authenticate locally using Application Default Credentials (ADC).
   - Verify that the three buckets and the Secret Manager secret exist and are accessible.
   - Output the total number of media objects in each bucket on three separate lines (e.g., `development: 14`, `production: 3365`).

3. **Rails Configuration**:
   - Update `config/storage.yml` to map to the new GCS buckets, inspired by `rails8-turbo-chat-2026`.
   - Ensure the Rails app expects most secrets via standard Rails encrypted credentials, relying on the environment or GCP Secret Manager only for the master key bootstrap.

## Non-Functional Requirements
- **Security**: Principle of least privilege for the Cloud Run Service Account.
- **Idempotency**: The checking script and infrastructure scripts must be safely re-runnable.

## Out of Scope
- Full Cloud SQL setup (Cloud SQL will be handled in a dedicated track).
