<!-- ⚠️ AGENT WARNING: This file (SKELETON.md) and CODELAB.md must be kept in sync at all times. A change to one requires a change to the other! -->
<!-- 📜 Adheres to docs/CONSTITUTION.md (v1.1.0) -->
# Workshop Skeleton

This is the canonical high-level roadmap and step breakdown for the Rails 8 on Google Cloud workshop, designed around the **3 Progressive Cloud Run Deployments**, **Zero-Branch Time-Machine overlays**, and **Google Antigravity pair programming**:

---

### Step 0: Prerequisites, Antigravity Setup & Billing Verification
- **`needs`**: Google Cloud Account, installed CLIs (`gcloud`, `terraform`, `docker`, `ruby` 3.3+, `rails` 8), Google Antigravity IDE / extension.
- **`does`**:
  - Clone repository and authenticate: `gcloud auth login` and `gcloud auth application-default login`.
  - Set active project: `gcloud config set project <PROJECT_ID>`.
  - Mandatory guard gate: run `gcloud beta billing projects describe <PROJECT_ID>` to verify billing/credits are active (prevents cryptic mid-workshop failures).
- **`wow`**: Antigravity connects directly to the codebase and verifies the local development environment in seconds!
- **`creates`**: Verified environment, authenticated ADC, and confirmed billing foundation.

---

### Step 1: Terraform Infrastructure Kickoff & Pre-Flight Diagnostics
- **`needs`**: Step 0 completed.
- **`does`**:
  - Run the automated pre-flight diagnostics suite: `just workshop-test` 🧪 (verifies Gmail identity, billing state, ADC credentials, master key, and GCS canary status).
  - Launch immutable infrastructure via Terraform (`cd iac && terraform apply` or `just terraform-apply`).
  - Provisions: GCS bucket with IAM Credentials signing (`iam: true`), uploads the canary seed image (`seeds/gcs_dev_image.jpg`), and starts Cloud SQL PostgreSQL provisioning in the background (~10-12 mins).
- **`wow`**: One command starts heavy Cloud SQL provisioning in the background while students continue developing locally without waiting!
- **`creates`**: Background Cloud SQL build cooking in GCP, active private GCS bucket with canary asset.

---

### Step 2: The Local Baseline, Mailpit & Admin Onboarding
- **`needs`**: Step 1 launched. Working on `main` (baseline mode).
- **`does`**:
  - Launch local Docker Compose stack (`docker compose up` or `bin/dev`).
  - Configure `ADMIN_EMAIL` with the student's email address (or let seeds default).
  - Run `bin/rails db:seed` which triggers a welcome email via ActionMailer.
  - Open **Mailpit UI** (`http://localhost:8025`) to catch the local email without sending external spam!
  - Drop into `bin/rails console` to inspect `User.last` and practice password verification.
  - Create a blog post, test rich-text editing with ActionText, and observe the `[EPHEMERAL DB / STORAGE]` badge in the UI.
- **`wow`**: Instant local gratification: rich text editor, email interception in Mailpit, and interactive Rails console mastery in under 5 minutes!
- **`creates`**: Verified local Rails 8 baseline and clear motivation for cloud persistence.

---

### Step 3: Deploy 1 — The Stateless Shock (Early WOW!)
- **`needs`**: Step 2 completed.
- **`does`**:
  - Rewind local configuration to Stage 1: `just workshop-rewind 1` (SQLite on container disk, storage on local disk).
  - Deploy single Puma container directly to Cloud Run: `gcloud run deploy blog --source . --region us-central1 --allow-unauthenticated`.
  - Bootstrap initial admin securely via server-side ENV variables (`ADMIN_EMAIL`, `ADMIN_PASSWORD` - Issue #21).
  - Open public Cloud Run URL, create a post, upload a photo.
  - **The Stateless Shock:** Force a container restart/revision. Reload the page: the SQLite post and local image are gone!
- **`wow`**: Live public Cloud Run URL in under 3 minutes, with an unforgettable hands-on demonstration of serverless statelessness!
- **`creates`**: First live Cloud Run deployment (D1) and visceral motivation for GCS and Cloud SQL.

---

### Step 4: Deploy 2 — GCS Persistent Storage & POLA Warning
- **`needs`**: Step 3 completed, GCS bucket ready from Step 1.
- **`does`**:
  - Rewind/advance configuration to Stage 2: `just workshop-rewind 2` (SQLite still ephemeral, ActiveStorage pointed to GCS with `iam: true`).
  - Redeploy to Cloud Run: `gcloud run deploy blog --source .`.
  - Create a post with an uploaded image. Force another container restart: relational text resets, but the image survived on GCS!
  - **⚠️ POLA Teachable Moment (Issue #22):** Background jobs banner (`_check_stuck_jobs`) appears in UI warning that jobs are queued without a worker container.
- **`wow`**: Uploaded photos survive container restarts on Google Cloud Storage even while the database is still ephemeral!
- **`creates`**: Second live Cloud Run deployment (D2), verified GCS IAM signing, and clear motivation for Cloud SQL + Solid Queue workers.

---

### Step 5: Cloud SQL Ready & Secret Manager CLI Injection
- **`needs`**: Step 4 completed. Cloud SQL instance provisioned (~12 min timer completed).
- **`does`**:
  - Verify Cloud SQL instance is in `RUNNABLE` state.
  - Upload application secrets to Google Cloud Secret Manager via CLI:
    - `gcloud secrets create rails-master-key --data-file=config/master.key`
    - `gcloud secrets create rails-db-password --data-file=<(echo -n "$DB_PASSWORD")`
  - Grant `roles/secretmanager.secretAccessor` to the Cloud Run runtime Service Account.
  - Test encrypted mTLS tunnel locally using `cloud-sql-proxy` on `127.0.0.1:5432`.
- **`wow`**: Zero plain-text credentials in git or `.env` files; encrypted runtime injection directly from Secret Manager!
- **`creates`**: Encrypted secrets in Secret Manager and verified Cloud SQL connectivity.

---

### Step 6: Deploy 3 — Enterprise Multi-Container Sidecars (The Gold Standard)
- **`needs`**: Step 5 completed.
- **`does`**:
  - Restore repository to Gold Standard: `just workshop-restore-gold` (returns to `main`).
  - Review multi-container orchestration architecture (`compose.prod.yaml`):
    1. `web`: Rails Puma server on port 8080.
    2. `worker`: Solid Queue background processor.
    3. `cloudsql-proxy`: Official Google sidecar container on `localhost:5432`.
  - Deploy the multi-container configuration to Cloud Run with Secret Manager references.
  - Run database migration job on Cloud SQL.
  - UI badge turns green: `[CLOUD PERSISTENT 🐘 ☁️]`. The stuck jobs warning disappears as the worker container drains queued tasks!
- **`wow`**: A production-grade multi-container sidecar architecture boots serverlessly on Cloud Run with full database persistence and active background workers!
- **`creates`**: Third live Cloud Run deployment (D3) — the canonical enterprise Rails 8 architecture.

---

### Step 7: Generative AI Pipelines, Podcastifier & The GCS Treasure Hunt 🏴‍☠️
- **`needs`**: Step 6 completed, `GEMINI_API_KEY` configured.
- **`does`**:
  - Test **NanoBanana Cover Generator** (`GenerateCoverImageJob`): posts published without a cover automatically receive a vintage 1960s Italian poster with a cameo banana via Imagen/Gemini.
  - Test **Podcastifier** (bilingual audio synthesis): translates post to Italian and synthesizes `.mp3` audio using Google Cloud Text-to-Speech (see [ideas in docs/ideas/WORKSHOP_IDEAS.md](../docs/ideas/WORKSHOP_IDEAS.md)).
  - **🏴‍☠️ The Orphan Blob Treasure Hunt:** Use `bin/rails console` on Cloud Run to find and reconnect the lonely image blob uploaded during Step 4 to a new Cloud SQL post!
- **`wow`**: Live GenAI image generation and audio synthesis running asynchronously in background workers, plus recovering orphan cloud data via Rails console!
- **`creates`**: Full showcase of modern AI integrations on top of serverless Rails 8.

---

### Step 8: Choose Your Own Adventure / Advanced Quests 🏆
- **`needs`**: Step 7 completed.
- **`does`**:
  - Open-ended capstone quests for students to explore advanced Google Cloud patterns:
    - 🛡️ **Quest 1 (Enterprise Security - Identity-Aware Proxy)**: Configure Google Cloud IAP + Load Balancer using `IapAuthenticatable` concern and `iac/iap.tf`.
    - 📊 **Quest 2 (SRE Observability)**: Structured JSON logging, trace correlation IDs, and Cloud Error Reporting.
    - 🧠 **Quest 3 (GenAI Vector Search)**: Cloud SQL `pgvector` semantic embeddings search using Gemini `text-embedding-004`.
    - 📝 **Quest 4 (SEO & Metadata Assistant)**: Automated Gemini summary, tag generation, and Fog readability index (see [`docs/ideas/WORKSHOP_IDEAS.md`](../docs/ideas/WORKSHOP_IDEAS.md)).
- **`wow`**: Enterprise zero-trust security, deep SRE observability, or vector AI search running on the student's live cloud deployment!
- **`creates`**: Graduation portfolio project and deep mastery of Rails 8 on Google Cloud.

---

## 🎯 Verification Checklist

- [x] Step 0: Prerequisites & Billing Verification
- [x] Step 1: Terraform Infrastructure & Diagnostics (`just workshop-test`)
- [x] Step 2: Local Baseline & Mailpit Experience
- [x] Step 3: Deploy 1 — Stateless Shock (Cloud Run Single Container)
- [x] Step 4: Deploy 2 — GCS Storage Uplift & POLA Stuck Jobs Warning
- [x] Step 5: Secret Manager & Cloud SQL Auth Proxy Setup
- [x] Step 6: Deploy 3 — Multi-Container Sidecars (Web + Worker + Proxy)
- [x] Step 7: GenAI Features, Podcastifier & GCS Treasure Hunt
- [x] Step 8: Advanced Quests (IAP, SRE, pgvector, SEO Assistant)
