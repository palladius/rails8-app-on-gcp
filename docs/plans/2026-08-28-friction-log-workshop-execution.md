# Rails 8 on GCP Workshop Friction Log & Reproduction Implementation Plan

> **For Gemini:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Autonomously provision a temporary 3-day GCP project (`rails8-fl-repro-20260828`), execute the Rails 8 on Google Cloud workshop end-to-end via `devrel-frictionlog-codelab`, document all friction points in `docs/private/auto-friction-log-20260828.md`, evaluate technical and aesthetic alignment with `docs/ESTHTEICS.md`, and produce actionable issue/PR specifications in `docs/private/workshop-frictionlog-actionable-improvements-20260828.md`.

**Architecture:** Automated test infrastructure provisioned via Google Cloud CLI (`gcloud`) and Terraform (`iac/`). Workshop executed step-by-step from `workshop/CODELAB.md` using the structured DevRel friction logging protocol (timestamped actions, emoji ratings 🟢/🟡/🔴, empirical validation checkpoints, isolated workbench). Findings are partitioned between the pure friction log and an actionable improvement backlog.

**Tech Stack:** Google Cloud (Cloud Run multi-container, Cloud SQL PostgreSQL, GCS with IAM blob signing, Secret Manager, Vertex AI Gemini/Imagen), Ruby on Rails 8, Solid Queue, Docker Compose, Terraform, Bash.

---

### Task 1: Friday Afternoon Unblocking Checklist for Riccardo 🦖

**Files:**
- Reference: `docs/CUJs/friction-log-the-workshop-w-smart-loop.md`
- Reference: `~/.gemini/config/plugins/palladius-private-goodies/skills/gcp-setup-for-googlers/SKILL.md`

**Step 1: Verify Google internal credentials & ADC**
Ensure Riccardo is logged in with corporate credentials (`ricc@google.com`) and ADC is active before leaving:
```bash
gcloud config set account ricc@google.com
gcloud auth list
gcloud auth application-default print-access-token > /dev/null && echo "✅ ADC Valid"
```

**Step 2: Verify gcloud impersonation status**
Ensure no lingering service account impersonation blocks project creation:
```bash
gcloud config get-value auth/impersonate_service_account
# If set, clear with: gcloud config set auth/impersonate_service_account ""
```

**Step 3: Confirm Target Parameters**
- **Project ID**: `rails8-fl-repro-20260828`
- **Target Folder**: `1053275019153` (`untrusted / demos / cloud-devrel-demos-untrusted`)
- **3-Day Billing Account**: `012914-9E95D1-A1EEE8` (`See http://go/gcp-using-gcp#short-term any registered org 3 days`)
- **GCP Region**: `europe-west1`

---

### Task 2: Temporary GCP Project Provisioning (`rails8-fl-repro-20260828`)

**Files:**
- Create: `workbench/01_setup_project.sh`

**Step 1: Write project setup script**
Create `workbench/01_setup_project.sh` to deterministically create the project, link 3-day billing, and enable required GCP APIs:
```bash
#!/bin/bash
set -euo pipefail

PROJECT_ID="rails8-fl-repro-20260828"
FOLDER_ID="1053275019153"
BILLING_ACCOUNT="012914-9E95D1-A1EEE8"
REGION="europe-west1"

echo "🚀 [1/4] Creating GCP Project ${PROJECT_ID}..."
gcloud projects create "${PROJECT_ID}" --folder="${FOLDER_ID}" --name="Rails8 FL Repro 20260828" || true

echo "💳 [2/4] Linking 3-Day Billing Account ${BILLING_ACCOUNT}..."
gcloud beta billing projects link "${PROJECT_ID}" --billing-account="${BILLING_ACCOUNT}"

echo "🔧 [3/4] Setting active project context..."
gcloud config set project "${PROJECT_ID}"

echo "⚡ [4/4] Enabling required Google Cloud APIs..."
gcloud services enable \
  compute.googleapis.com \
  run.googleapis.com \
  sqladmin.googleapis.com \
  storage.googleapis.com \
  secretmanager.googleapis.com \
  cloudbuild.googleapis.com \
  iamcredentials.googleapis.com \
  aiplatform.googleapis.com \
  artifactregistry.googleapis.com \
  --project="${PROJECT_ID}"

echo "✅ Project ${PROJECT_ID} successfully provisioned and ready!"
```

**Step 2: Run project setup script**
Run: `bash workbench/01_setup_project.sh`
Expected: Project created, billing linked, APIs enabled.

**Step 3: Empirically verify billing and project state**
Run: `gcloud beta billing projects describe rails8-fl-repro-20260828`
Expected: `billingEnabled: true` and `billingAccountName: billingAccounts/012914-9E95D1-A1EEE8`.

---

### Task 3: Friction Log Workspace & Scaffolding Initialization

**Files:**
- Create: `docs/private/auto-friction-log-20260828.md`
- Create: `docs/private/workshop-frictionlog-actionable-improvements-20260828.md`
- Create: `out/20260828-frictionlog-rails8-workshop/friction_log.yaml`
- Create: `out/20260828-frictionlog-rails8-workshop/BUGS.md`
- Create directory: `out/20260828-frictionlog-rails8-workshop/friction_log/by-page/`

**Step 1: Create directories**
```bash
mkdir -p docs/private
mkdir -p out/20260828-frictionlog-rails8-workshop/friction_log/by-page
mkdir -p out/20260828-frictionlog-rails8-workshop/workbench
```

**Step 2: Initialize metadata in `out/20260828-frictionlog-rails8-workshop/friction_log.yaml`**
```yaml
apiVersion: devrel.google.com/v1alpha1
kind: FrictionLog
metadata:
  title: "Rails 8 on Google Cloud Workshop Friction Log"
  codelabUrl: "https://github.com/palladius/rails8-app-on-gcp/blob/main/workshop/CODELAB.md"
  startedAt: "2026-08-28T14:00:00+02:00"
  identity: "ricc@google.com"
  projectId: "rails8-fl-repro-20260828"
  hostname: "derek"
  products:
    - Cloud Run
    - Cloud SQL (PostgreSQL)
    - Google Cloud Storage (IAM Blob Signing)
    - Secret Manager
    - Solid Queue
    - Vertex AI (Gemini / Imagen)
  languages:
    - Ruby
    - Terraform
    - Bash
    - Dockerfile / Compose
```

**Step 3: Initialize `docs/private/auto-friction-log-20260828.md` and `docs/private/workshop-frictionlog-actionable-improvements-20260828.md`**
Seed headers and formatting templates matching `devrel-frictionlog-codelab` standards.

---

### Task 4: Infrastructure Provisioning via Terraform (`iac/`)

**Files:**
- Modify: `iac/terraform.tfvars` (create temporary instance-specific variables if not using default CLI flags)
- Reference: `iac/main.tf`, `iac/database.tf`, `iac/storage.tf`, `iac/secrets.tf`, `iac/cloudrun.tf`

**Step 1: Initialize GCS backend state bucket**
```bash
BUCKET_NAME="rails8-fl-repro-20260828-tfstate"
gcloud storage buckets create "gs://$BUCKET_NAME" --project="rails8-fl-repro-20260828" --location="europe-west1" --uniform-bucket-level-access || true
```

**Step 2: Initialize Terraform**
```bash
cd iac
terraform init -backend-config="bucket=rails8-fl-repro-20260828-tfstate" -reconfigure
```

**Step 3: Apply Terraform to provision baseline resources**
```bash
terraform apply -auto-approve \
  -var="project_id=rails8-fl-repro-20260828" \
  -var="region=europe-west1" \
  -var='developers=["user:ricc@google.com"]' \
  -var="enable_iap=false"
```

**Step 4: Empirically verify provisioned resources**
- Verify Cloud SQL: `gcloud sql instances list --project=rails8-fl-repro-20260828`
- Verify GCS bucket: `gcloud storage buckets list --project=rails8-fl-repro-20260828`
- Verify Service Account: `gcloud iam service-accounts list --project=rails8-fl-repro-20260828`

---

### Task 5: Step-by-Step Autonomous Workshop Execution & Friction Logging

**Files:**
- Track: `out/20260828-frictionlog-rails8-workshop/friction_log/by-page/00_prerequisites.md`
- Track: `out/20260828-frictionlog-rails8-workshop/friction_log/by-page/01_local_baseline.md`
- Track: `out/20260828-frictionlog-rails8-workshop/friction_log/by-page/02_cloud_storage.md`
- Track: `out/20260828-frictionlog-rails8-workshop/friction_log/by-page/03_cloud_sql.md`
- Track: `out/20260828-frictionlog-rails8-workshop/friction_log/by-page/04_secret_manager.md`
- Track: `out/20260828-frictionlog-rails8-workshop/friction_log/by-page/05_cloud_run.md`
- Track: `out/20260828-frictionlog-rails8-workshop/friction_log/by-page/06_cloud_build.md`
- Track: `out/20260828-frictionlog-rails8-workshop/friction_log/by-page/07_ai_features.md`
- Update: `docs/private/auto-friction-log-20260828.md`

#### Page 00: Prerequisites & Background Cloud SQL Kickoff
1. Verify tooling (`ruby -v`, `rails -v`, `terraform -v`, `docker -v`, `cloud-sql-proxy --version`).
2. Log friction on missing binaries or ambiguous instructions.
3. Verify background Cloud SQL provisioning kickoff.

#### Page 01: The Local Baseline, Seeds & Mailpit
1. Test `bundle install && bin/rails db:setup`.
2. Test `ADMIN_EMAIL="ricc@google.com" bin/rails db:seed`.
3. Test local boot (`bin/dev` and `docker compose up`).
4. Test Mailpit at `http://localhost:8025` for password resets / emails.
5. Log rating, technical friction, and UI/aesthetic feedback.

#### Page 02: Cloud Storage & IAM Blob Signing
1. Inspect `config/storage.yml` (`iam: true` vs legacy `service_account_key.json`).
2. Test upload directly to GCS bucket using active ADC credentials.
3. Validate signed URL generation and expiration.
4. Log security anti-patterns avoided (`0.0.0.0/0` public bucket vs private IAM).

#### Page 03: Cloud SQL (Naive Exposure vs Cloud SQL Auth Proxy)
1. Verify Phase 3A (anti-pattern: authorized networks `0.0.0.0/0` vs security risk).
2. Verify Phase 3B (`cloud-sql-proxy --port 5432`).
3. Run `DATABASE_URL=postgresql://... bin/rails db:migrate db:seed` through local proxy.
4. Verify database persistence and UI status badge change.

#### Page 04: Google Cloud Secret Manager
1. Create `rails-master-key` and `rails-db-password` secrets.
2. Grant `roles/secretmanager.secretAccessor` to compute service account.
3. Verify secret access from CLI and container environment.

#### Page 05: Multi-Container Cloud Run & Docker Compose
1. Inspect `compose.prod.yaml` (`web` + `worker` + `cloudsql-proxy`).
2. Test local multi-container boot with Docker Compose.
3. Deploy to Cloud Run:
   ```bash
   gcloud run deploy rails-blog --source . --region europe-west1 --set-secrets="..."
   ```
4. Empirical live check: `curl -I <CLOUD_RUN_SERVICE_URL>` and verify `200 OK`.

#### Page 06: Cloud Build Automation
1. Inspect `cloudbuild.yaml`.
2. Validate pipeline step semantics (Build -> Migrate Job -> Deploy).
3. Document friction regarding manual GitHub trigger connection in automated headless runs.

#### Page 07: AI Background Features (NanoBanana & Solid Queue)
1. Inspect `GenerateCoverImageJob` and Vertex AI Gemini/Imagen integration.
2. Create test post without image, trigger background worker.
3. Empirically verify Solid Queue execution and ActiveStorage attachment of the generated vintage poster.

---

### Task 6: Technical & Aesthetic Evaluation against `docs/ESTHTEICS.md`

**Files:**
- Reference: `docs/ESTHTEICS.md`
- Output: Section in `docs/private/auto-friction-log-20260828.md` and `docs/private/workshop-frictionlog-actionable-improvements-20260828.md`

**Step 1: Audit DRYness & Default over Configuration**
- Check if unnecessary ports, config flags, or repetitive `.env` variables are required from the student.
- Verify whether sensible defaults work out of the box.

**Step 2: Audit Mental Fatigue & Cognitive Friction**
- Check if command sequences are clear, copy-pasteable, and error-tolerant.
- Check if error messages explain *why* something failed in plain language.

**Step 3: Audit Storytelling & Visual Clues**
- Check if UI environment badges (🟡 `[EPHEMERAL DB]` vs 🟢 `[CLOUD SQL PERSISTENT]`) update accurately between steps.
- Check seeded blog posts narrative progression.

---

### Task 7: Comprehensive Synthesis & Actionable Improvement Delivery

**Files:**
- Create: `docs/private/auto-friction-log-20260828.md` (Consolidated Run Friction Log)
- Create: `docs/private/workshop-frictionlog-actionable-improvements-20260828.md` (Actionable Backlog & PR Specifications)

**Step 1: Compile `docs/private/auto-friction-log-20260828.md`**
- Executive Summary table (Project ID, Time, Identity, Hostname, Completion Status, Overall Experience).
- Consolidated chronological page-by-page logs with timestamps and ratings (🟢/🟡/🔴).
- Estimated human time vs AI execution time per step.

**Step 2: Compile `docs/private/workshop-frictionlog-actionable-improvements-20260828.md`**
- Explicit GitHub Issue drafts (Title, Problem, Proposed Solution, Acceptance Criteria).
- Proposed Code & Markdown Patches with exact git diffs.
- Clear instructions and priorities (P0 / P1 / P2) so any subsequent agent or engineer can immediately pick up implementation.

---

## Verification Plan

### Automated & CLI Verification
- Verification of project & billing: `gcloud beta billing projects describe rails8-fl-repro-20260828`
- Verification of terraform outputs: `terraform output -json`
- Verification of live Cloud Run URL: `curl -f -s -o /dev/null -w "%{http_code}" <CLOUD_RUN_URL>`
- Verification of test suite: `just test` (or `cd blog && bundle exec rails test`)

### Manual / DevRel Inspection
- Inspection of generated friction log in `docs/private/auto-friction-log-20260828.md`
- Inspection of actionable backlog in `docs/private/workshop-frictionlog-actionable-improvements-20260828.md`
