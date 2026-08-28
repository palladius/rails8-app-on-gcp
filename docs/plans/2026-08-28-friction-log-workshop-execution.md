# Rails 8 on GCP Workshop Friction Log & Reproduction Implementation Plan

> **For Gemini:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Autonomously provision a temporary 3-day GCP project (`rails8-fl-repro-20260828`), clone an isolated workspace (`~/git/rails8-app-on-gcp_FL_20260828`), execute the Rails 8 on Google Cloud workshop end-to-end via `devrel-frictionlog-codelab`, document all friction points in `docs/private/auto-friction-log-20260828.md`, evaluate technical/aesthetic UX against `docs/ESTHTEICS.md`, and generate actionable issue/PR specifications in `docs/private/workshop-frictionlog-actionable-improvements-20260828.md`.

**Architecture:** Automated test infrastructure provisioned via Google Cloud CLI (`gcloud`) and Terraform (`iac/`). Workshop executed step-by-step from `workshop/CODELAB.md` using the structured DevRel friction logging protocol (timestamped actions, emoji ratings 🟢/🟡/🔴, empirical validation checkpoints, isolated workbench). Code is preserved via local `dont_commit_step_X` checkpoint branches with zero remote push.

**Tech Stack:** Google Cloud (Cloud Run multi-container, Cloud SQL PostgreSQL, GCS with IAM blob signing, Secret Manager, Vertex AI Gemini/Imagen), Ruby on Rails 8, Solid Queue, Docker Compose, Terraform, Bash.

---

### Task 1: Friday Unblocking & Isolated Environment Scaffolding

**Files:**
- Reference: `docs/CUJs/friction-log-the-workshop-w-smart-loop.md`
- Reference: `~/.gemini/config/plugins/palladius-private-goodies/skills/gcp-setup-for-googlers/SKILL.md`

**Step 1: Check ADC Token status**
Run: `gcloud auth application-default print-access-token >/dev/null`
Expected: Return 0 (valid ADC credentials).

**Step 2: Clone fresh isolated workspace**
```bash
git clone /usr/local/google/home/ricc/git/rails8-app-on-gcp ~/git/rails8-app-on-gcp_FL_20260828
cd ~/git/rails8-app-on-gcp_FL_20260828
```

**Step 3: Setup directories and metadata**
```bash
mkdir -p docs/private
mkdir -p out/20260828-frictionlog-rails8-workshop/friction_log/by-page
mkdir -p out/20260828-frictionlog-rails8-workshop/workbench
```

---

### Task 2: Temporary GCP Project Provisioning (`rails8-fl-repro-20260828`)

**Files:**
- Create: `out/20260828-frictionlog-rails8-workshop/workbench/01_setup_project.sh`

**Step 1: Create project setup script**
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

**Step 2: Run and verify project setup**
Run: `bash out/20260828-frictionlog-rails8-workshop/workbench/01_setup_project.sh`
Run: `gcloud beta billing projects describe rails8-fl-repro-20260828`
Expected: `billingEnabled: true`.

---

### Task 3: Infrastructure Provisioning via Terraform (`iac/`)

**Files:**
- Reference: `iac/main.tf`, `iac/database.tf`, `iac/storage.tf`, `iac/secrets.tf`, `iac/cloudrun.tf`

**Step 1: Create state bucket**
```bash
gcloud storage buckets create "gs://rails8-fl-repro-20260828-tfstate" --project="rails8-fl-repro-20260828" --location="europe-west1" --uniform-bucket-level-access || true
```

**Step 2: Initialize & Apply Terraform**
```bash
cd ~/git/rails8-app-on-gcp_FL_20260828/iac
terraform init -backend-config="bucket=rails8-fl-repro-20260828-tfstate" -reconfigure
terraform apply -auto-approve \
  -var="project_id=rails8-fl-repro-20260828" \
  -var="region=europe-west1" \
  -var='developers=["user:ricc@google.com", "user:riccardolobotomy@gmail.com"]' \
  -var="enable_iap=false"
```

---

### Task 4: Step-by-Step Autonomous Workshop Execution & Friction Logging

Execute steps sequentially in `~/git/rails8-app-on-gcp_FL_20260828/`:
- **Step 00 / Prerequisites**: Tooling validation, clone checkout.
- **Step 01 / Local Baseline & Mailpit**: `bin/rails db:setup`, `ADMIN_EMAIL="riccardolobotomy@gmail.com" bin/rails db:seed`, Mailpit verification, snapshot to `dont_commit_step_1`.
- **Step 02 / Cloud Storage**: ActiveStorage GCS migration with `iam: true`, drag & drop upload, signed URL check, snapshot to `dont_commit_step_2`.
- **Step 03 / Cloud SQL**: Anti-pattern test vs Cloud SQL Auth Proxy sidecar, migration & seed test, snapshot to `dont_commit_step_3`.
- **Step 04 / Secret Manager**: Secret creation, IAM role grants, snapshot to `dont_commit_step_4`.
- **Step 05 / Multi-Container Cloud Run**: Docker Compose local test, Cloud Run deployment, live URL health check (`curl -I`), snapshot to `dont_commit_step_5`.
- **Step 06 / Cloud Build Automation**: Inspect `cloudbuild.yaml`, pipeline validation, snapshot to `dont_commit_step_6`.
- **Step 07 / AI Features**: `GenerateCoverImageJob` background worker test via Solid Queue, vintage Italian poster image attachment verification, snapshot to `dont_commit_step_7`.

---

### Task 5: Aesthetic & Technical Evaluation against `docs/ESTHTEICS.md`

- Audit DRYness & Default over Configuration.
- Audit student mental fatigue & copy-paste reliability.
- Audit visual clues (dynamic environment badges & seeded posts narrative).

---

### Task 6: Synthesis & Actionable Improvement Delivery

- Compile `docs/private/auto-friction-log-20260828.md` (clean, timestamped friction log).
- Compile `docs/private/workshop-frictionlog-actionable-improvements-20260828.md` (actionable issue/PR specs and git diffs).
