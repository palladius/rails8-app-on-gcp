<!-- ⚠️ AGENT WARNING: This file (SKELETON.md) is compiled from workshop/skeleton.yaml. DO NOT EDIT DIRECTLY! -->
<!-- 📜 Adheres to docs/CONSTITUTION.md (v1.1.0) -->
# Workshop Skeleton

This is the canonical high-level roadmap and step breakdown for the Rails 8 on Google Cloud workshop, designed around the **3 Progressive Cloud Run Deployments**, **Zero-Branch Time-Machine overlays**, and **Google Antigravity pair programming**:

---

### Step 0: Prerequisites, Antigravity Setup & Billing Verification
- **`description`**: Verify local toolchain, Google Cloud authentication, project selection, and billing status before writing code.
- **`prerequisites`**:
  - Google Cloud Account with active credits or billing account
  - Git 2.30+ for cloning and branching repository
  - Installed CLIs: git, gcloud, terraform, docker, ruby 3.3+, rails 8
  - Google Antigravity IDE or Gemini CLI environment
- **`pseudocode`**:
  ```bash
  gcloud config configurations create rails8-on-gcp-workshop --activate 2>/dev/null || gcloud config configurations activate rails8-on-gcp-workshop
  gcloud auth login $GOOGLE_CLOUD_ACCOUNT && gcloud auth application-default login
  gcloud config set project $GOOGLE_CLOUD_PROJECT
  gcloud beta billing projects describe $GOOGLE_CLOUD_PROJECT
  ```
- **`postrequisites`**:
  - Authenticated gcloud and Application Default Credentials (ADC)
  - Verified active billing account preventing mid-workshop quota failures
  - Antigravity connected and paired with repository
- **`evals`**:
  - `[SHELL]` Verify git CLI is installed and returns valid version
  - `[SHELL]` Verify gcloud CLI is installed and returns valid version
  - `[SHELL]` Verify Application Default Credentials file exists or can print token
  - `[RUBY]` Check Ruby version is 3.3 or higher

---

### Step 1: Terraform Infrastructure Kickoff & Pre-Flight Diagnostics
- **`description`**: Execute pre-flight diagnostics suite and kick off Terraform infrastructure in the background.
- **`prerequisites`**:
  - Step 0 completed and billing verified
  - Terraform CLI 1.5+ installed
- **`pseudocode`**:
  ```bash
  just workshop-test
  cd iac && terraform init && terraform apply -auto-approve
  ```
- **`postrequisites`**:
  - Passing pre-flight diagnostics suite (workshop-test)
  - GCS bucket provisioned with IAM Credentials signing (iam: true)
  - Canary seed image uploaded to GCS
  - Cloud SQL PostgreSQL provisioning cooking in the background (~10-12 mins)
- **`evals`**:
  - `[SHELL]` Run automated pre-flight workshop diagnostics
  - `[RUBY]` Verify Terraform main configuration file exists and has valid syntax

---

### Step 2: The Local Baseline, Mailpit & Admin Onboarding
- **`description`**: Run local Docker Compose stack, seed the database with admin identity, intercept welcome email in Mailpit, and inspect models.
- **`prerequisites`**:
  - Step 1 kicked off
  - Local Docker engine running
- **`pseudocode`**:
  ```bash
  cp .env.dist .env && vim .env # set GOOGLE_CLOUD_ACCOUNT
  docker compose up -d
  bin/rails db:prepare db:seed
  open http://localhost:8025 # Mailpit
  ```
- **`postrequisites`**:
  - Running local Rails 8 application with SQLite/Docker Postgres
  - Admin account bootstrapped from GOOGLE_CLOUD_ACCOUNT
  - Intercepted welcome/reset password email in local Mailpit
  - Observed [EPHEMERAL DB / STORAGE] UI badge
- **`evals`**:
  - `[SHELL]` Verify local Rails test suite passes
  - `[SHELL]` Verify integration test suite for workshop header alerts (SQL, Storage, AI) passes
  - `[RUBY]` Verify db/seeds.rb enforces GOOGLE_CLOUD_ACCOUNT presence
  - `[LLM]` Evaluate student's first local blog post for creativity and workshop adherence

---

### Step 3: Deploy 1 — The Stateless Shock (Early WOW!)
- **`description`**: Deploy a single stateless Puma container directly to Cloud Run to witness the Stateless Shock when ephemeral containers restart.
- **`prerequisites`**:
  - Step 2 completed
  - Cloud Run API enabled in GCP project
- **`pseudocode`**:
  ```bash
  just workshop-rewind 1
  gcloud run deploy blog --source . --region us-central1 --allow-unauthenticated --set-env-vars GOOGLE_CLOUD_ACCOUNT=$GOOGLE_CLOUD_ACCOUNT
  # Notice stuck jobs banner, attempt workaround via SOLID_QUEUE_IN_PUMA=true, observe lost data
  gcloud run services update blog --region us-central1 --update-env-vars SOLID_QUEUE_IN_PUMA=true
  ```
- **`postrequisites`**:
  - First live public HTTPS URL on Cloud Run
  - First-hand experience of container disk ephemeral resets (lost SQLite posts & images)
  - Clear motivation for Google Cloud Storage and managed Cloud SQL
- **`evals`**:
  - `[SHELL]` Verify Cloud Run service exists and is responding (dry-run/check)
  - `[RUBY]` Verify missing admin alert partial is present in views
  - `[RUBY]` Verify docker-entrypoint automatically runs db:seed to bootstrap admin user
  - `[LLM]` Verify that Cloud Run boot sequence creates admin and does NOT display missing admin alert

---

### Step 4: Deploy 2 — GCS Persistent Storage & POLA Warning
- **`description`**: Point ActiveStorage to Google Cloud Storage with private IAM signing and observe the POLA stuck jobs warning banner.
- **`prerequisites`**:
  - Step 3 completed
  - GCS bucket provisioned from Step 1
- **`pseudocode`**:
  ```bash
  just workshop-rewind 2
  gcloud run deploy blog --source . --set-env-vars GCS_BUCKET=$GCS_BUCKET
  # Observe surviving images & stuck jobs banner
  ```
- **`postrequisites`**:
  - Uploaded media survives container restarts in private GCS bucket
  - Signed blob URLs functioning via IAM Credentials API
  - Pedagogical stuck jobs warning (_check_stuck_jobs) visible in UI
- **`evals`**:
  - `[RUBY]` Verify storage.yml defines google service with IAM signing
  - `[SHELL]` Verify integration test for stuck jobs banner passes

---

### Step 5: Cloud SQL Ready & Secret Manager CLI Injection
- **`description`**: Verify Cloud SQL instance provisioning is finished and inject sensitive secrets into Google Cloud Secret Manager.
- **`prerequisites`**:
  - Step 4 completed
  - Cloud SQL instance provisioned and in RUNNABLE state
- **`pseudocode`**:
  ```bash
  gcloud sql instances describe rails-postgres --format='value(state)'
  gcloud secrets create rails-master-key --data-file=blog/config/master.key
  gcloud secrets add-iam-policy-binding rails-master-key --member="serviceAccount:$SA_EMAIL" --role="roles/secretmanager.secretAccessor"
  ```
- **`postrequisites`**:
  - Secrets stored securely in Secret Manager (zero credentials in git or env files)
  - Cloud Run runtime Service Account granted Secret Accessor role
  - Local mTLS proxy connectivity verified via cloud-sql-proxy
- **`evals`**:
  - `[SHELL]` Verify Secret Manager API is accessible or offline environment check
  - `[RUBY]` Verify master.key exists locally
  - `[RUBY]` Verify status telemetry infers Step 5 when Cloud SQL is configured before sidecars

---

### Step 6: Deploy 3 — Enterprise Multi-Container Sidecars (The Gold Standard)
- **`description`**: Deploy the full multi-container reference architecture on Cloud Run: Puma web, Solid Queue worker, and Cloud SQL Auth Proxy sidecar.
- **`prerequisites`**:
  - Step 5 completed
  - Cloud SQL and Secret Manager configured
- **`pseudocode`**:
  ```bash
  just workshop-restore-gold
  gcloud run deploy blog --source . # multi-container compose.prod.yaml
  bin/rails db:migrate
  ```
- **`postrequisites`**:
  - Production-grade multi-container sidecar architecture running serverlessly on Cloud Run
  - Solid Queue background workers actively draining queue
  - Persistent Cloud SQL PostgreSQL with connection pooling
  - UI badge turns green: [CLOUD PERSISTENT 🐘 ☁️]
- **`evals`**:
  - `[RUBY]` Verify multi-container production compose configuration contains web, worker, and proxy
  - `[SHELL]` Verify full test suite passes against gold standard
  - `[RUBY]` Verify that Solid Queue worker or supervisor is active and draining jobs
  - `[RUBY]` Verify status telemetry infers Step 6 on Cloud Run with Cloud SQL and GCS (non-AI baseline)

---

### Step 7: Generative AI Pipelines, Podcastifier & The GCS Treasure Hunt 🏴‍☠️
- **`description`**: Enable asynchronous background GenAI cover generation, text-to-speech podcast synthesis, and recover orphan cloud blobs via Rails console.
- **`prerequisites`**:
  - Step 6 completed
  - GEMINI_API_KEY or Vertex AI IAM permissions active
- **`pseudocode`**:
  ```bash
  gcloud run jobs execute ai-image-sync || bin/rails runner GenerateCoverImageJob.perform_now
  bin/rails console # ActiveStorage blob reconnection
  ```
- **`postrequisites`**:
  - Asynchronous GenAI image generation attached to blog posts
  - Bilingual TTS audio podcast generation functional
  - Successful recovery of orphaned Step 4 GCS blob connected to Cloud SQL post
- **`evals`**:
  - `[RUBY]` Verify GenerateCoverImageJob exists
  - `[LLM]` Verify GenAI prompt conforms to Milanese vintage poster aesthetic
  - `[RUBY]` Verify Podcastifier exists as a minimal student scaffold stub (< 10 lines with COMPLETE_ME)
  - `[LLM]` Verify student implementation of Podcastifier via Antigravity if attempted
  - `[RUBY]` Verify deterministic absence of warning alerts, stuck jobs, and ephemeral badges via integration tests
  - `[LLM]` Verify rendered UI and screenshots at Step 7 have zero warning banners, zero pending background jobs alerts, and no ephemeral storage badges
  - `[RUBY]` Verify status telemetry infers Step 7 when Cloud Run has Cloud SQL, GCS, and active AI credentials

---

### Step 8: Choose Your Own Adventure / Advanced Quests 🏆
- **`description`**: Capstone enterprise challenges: Identity-Aware Proxy (IAP), Cloud Logging & Error Reporting, pgvector semantic search, or SEO Assistant.
- **`prerequisites`**:
  - Step 7 completed
- **`pseudocode`**:
  ```bash
  # Choose Quest: IAP, SRE Observability, pgvector, or SEO Assistant
  git checkout -b quest/iap-security
  ```
- **`postrequisites`**:
  - Graduation portfolio project completed
  - Deepened mastery of enterprise cloud-native patterns on Google Cloud
- **`evals`**:
  - `[RUBY]` Verify IAP authentication concern exists for Quest 1
  - `[LLM]` Evaluate student's capstone quest architecture and report

---

## 🛡️ Cumulative Cascading Invariants (Monotonic Checks)

Architectural milestones in the workshop are irreversible one-way doors. When running `just workshop-eval <N>`, all active cumulative invariants where `from_step <= N` are strictly enforced to eliminate ephemeral regressions:

- **`[INV: Step 0+]` Toolchain Integrity Invariant (CLIs on PATH)** (`inv-toolchain-integrity`)
  - *Description:* From Step 0 onward, essential workshop CLIs (git, gcloud, docker, terraform, ruby, just) must be available on PATH.
  - *Check Rule:* `toolchain_integrity`
- **`[INV: Step 2+]` Database Migration Currency Invariant** (`inv-database-migrations-current`)
  - *Description:* From Step 2 onward, the database schema must be current with zero pending migrations.
  - *Check Rule:* `database_migrations_current`
- **`[INV: Step 2+]` Admin User Bootstrap Invariant** (`inv-admin-user-seeded`)
  - *Description:* From Step 2 onward, the application database must contain at least one administrator user.
  - *Check Rule:* `admin_user_seeded`
- **`[INV: Step 4+]` GCS Persistent Storage Invariant (No Ephemeral Local Disk)** (`inv-persistent-gcs-storage`)
  - *Description:* From Step 4 onward, media storage cannot be :local; it must use Google Cloud Storage (:google_dev or :google_prod).
  - *Check Rule:* `no_local_storage`
- **`[INV: Step 6+]` Zero Stuck Jobs Invariant (Worker Sidecar Active)** (`inv-zero-stuck-background-jobs`)
  - *Description:* From Step 6 onward, Solid Queue worker must actively drain jobs. Pending background jobs cannot accumulate in queue.
  - *Check Rule:* `zero_stuck_jobs`
- **`[INV: Step 6+]` Cloud SQL Production Persistence Invariant** (`inv-cloud-sql-connected`)
  - *Description:* From Step 6 onward, production deployment cannot use ephemeral SQLite containers and must include Cloud SQL Auth Proxy sidecar.
  - *Check Rule:* `compose_has_service`
- **`[INV: Step 6+]` Three-Tier Multi-Container Topology Invariant** (`inv-three-tier-architecture`)
  - *Description:* From Step 6 onward, production deployment must define the full multi-container sidecar topology (web, worker, cloudsql-proxy).
  - *Check Rule:* `three_tier_architecture`

---

## 🎯 Verification Checklist

- [x] Step 0: Prerequisites, Antigravity Setup & Billing Verification
- [x] Step 1: Terraform Infrastructure Kickoff & Pre-Flight Diagnostics
- [x] Step 2: The Local Baseline, Mailpit & Admin Onboarding
- [x] Step 3: Deploy 1 — The Stateless Shock (Early WOW!)
- [x] Step 4: Deploy 2 — GCS Persistent Storage & POLA Warning
- [x] Step 5: Cloud SQL Ready & Secret Manager CLI Injection
- [x] Step 6: Deploy 3 — Enterprise Multi-Container Sidecars (The Gold Standard)
- [x] Step 7: Generative AI Pipelines, Podcastifier & The GCS Treasure Hunt 🏴‍☠️
- [x] Step 8: Choose Your Own Adventure / Advanced Quests 🏆
