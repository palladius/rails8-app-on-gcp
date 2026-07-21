# UAT and Testing Plan: GCP ActiveStorage & Arch Setup

This document outlines the testing strategy to ensure the GCS buckets, Secret Manager, Service Accounts, and Rails configurations are correctly implemented. **95% of these tests are automated** and will be executed by the AI Agent. The final **5% requires manual User Acceptance Testing (UAT)** to guarantee the end-to-end browser experience.

## Part 1: Automated Agent Tests (95% - AI Executed)

These tests will be run automatically during the implementation phases.

### 1.1 Infrastructure Validation (Phase 1)
- [ ] **Terraform Lint & Validate**: Run `terraform fmt -check` and `terraform validate` to ensure syntax correctness.
- [ ] **Terraform Plan**: Run `terraform plan` to confirm the expected resources (3 Buckets, 1 Service Account, 1 Secret, IAM bindings) will be created without destructive changes.

### 1.2 Resource Verification Script (Phase 3)
The custom `bin/check_gcp_setup` script acts as our primary test suite for GCP resources. The agent will run it and verify the following outputs:
- [ ] **Authentication Check**: Successfully authenticates using ADC.
- [ ] **Bucket Existence**: Confirms `dev`, `test`, and `prod` GCS buckets exist in the specified region.
- [ ] **Secret Manager Existence**: Confirms the `RAILS_MASTER_KEY` secret exists.
- [ ] **Media Count Check**: Successfully prints the 3 lines of media counts per environment (initially expected to be 0).

### 1.3 Rails Configuration Tests (Phase 2)
- [ ] **Storage YML Check**: Agent parses `config/storage.yml` to verify the `gcs` service is correctly defined and bound to the terraform-provisioned buckets.
- [ ] **Rails Runner Verification**: Agent executes `rails runner "puts ActiveStorage::Blob.service.name"` to confirm the app correctly resolves the GCS service based on the environment.

---

## Part 2: Manual User Acceptance Testing (5% - User Executed)

Once the agent completes the automated tests, you (the Supreme Leader) must perform these final checks.

### 2.1 End-to-End File Upload UAT
1. **Start the local server**: Run `bin/rails server`.
2. **Access the application**: Open `http://localhost:3000` in your browser.
3. **Upload Media**: Create a new Post (or edit an existing one) and attach an image or file.
4. **Verify Upload**: Ensure the web UI displays the image successfully without broken links.
5. **Verify GCP Landing**: Run the `bin/check_gcp_setup` script again. Ensure the `development` environment count increases by 1!

### 2.2 Local Secret Resolution UAT
1. **Verify Credentials**: Run `EDITOR="cat" bin/rails credentials:edit` and confirm that it successfully decrypts without relying on an embedded `master.key` file (proving it fetched it from the environment or secret manager fallback correctly, or proving the encrypted credential structure is intact).
