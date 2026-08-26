<!-- ⚠️ AGENT WARNING: This file (SKELETON.md) and CODELAB.md must be kept in sync at all times. A change to one requires a change to the other! -->
<!-- 📜 Adheres to workshop/UNTOUCHABLE-CONSTITUTION.md -->
# Workshop Skeleton

This is the high-level roadmap and step breakdown for the Rails 8 on Google Cloud workshop:

---

### Step 0: Setup & Async Cloud Provisioning
- **`needs`**: GCP Project (Billing enabled for Cloud SQL, or Free Tier for Zero-Billing track), installed CLIs (`gcloud`, `ruby` 3.3+, `rails` 8, `terraform`, `docker`, `cloud-sql-proxy`), Antigravity IDE / VS Code extension.
- **`does`**: Clone repo, authenticate with GCP (`gcloud auth login` & `gcloud auth application-default login`), verify billing, and immediately launch Cloud SQL + GCS provisioning in the background (`./bin/provision-cloudsql.sh` or `cd iac && terraform apply`). *(Zero-Billing track: skip Cloud SQL and use local/volume SQLite)*.
- **`wow`**: One command starts heavy cloud provisioning in the background without freezing the terminal!
- **`creates`**: Background infrastructure cooking in GCP (~10-12 mins) while students proceed immediately without blocking.

---

### Step 1: `workshop_1_local_baseline` (The Local Baseline & Exploration)
- **`needs`**: Step 0 completed, branch `workshop_1_local_baseline`.
- **`does`**:
  - Run `bundle install`, `bin/rails db:setup`, and `bin/dev`.
  - Log in with seeded user (`riccardo@example.com` / `Ch4ng3m3!!1`), create a post, and drag-and-drop an image directly into the ActionText editor.
  - **Gemini / Antigravity Exploration**: Prompt Gemini to inspect ActiveRecord models and generate a Mermaid ER diagram.
  - Discover why local SQLite & disk storage are ephemeral in container environments.
- **`wow`**: The app works locally in under 2 minutes with rich-text image drag-and-drop out of the box!
- **`creates`**: Verified local Rails 8 application and motivation for cloud-native persistence.

---

### Step 2: `workshop_2_cloud_storage` (ActiveStorage & GCS)
- **`needs`**: GCS Bucket ready from Step 0, branch `workshop_2_cloud_storage`.
- **`does`**:
  - Configure `config/storage.yml` with the `google` service and set `config.active_storage.service = :google`.
  - **Teachable Moment**: Configure `iam: true` for IAM Credentials blob signing; explain why `public: true` / `allUsers` is an insecure anti-pattern.
  - Drag-and-drop an image into the editor; inspect the network tab and GCS Console to see the blob land live in the cloud.
- **`wow`**: Dragging and dropping an image into Rails now auto-uploads directly to a private Google Cloud Storage bucket with expiring signed URLs!
- **`creates`**: Working ActiveStorage integration with private GCS bucket & expiring signed URLs.

---

### Step 3: `workshop_3_cloud_sql` (Cloud SQL: From Naive Exposure to Auth Proxy)
- **`needs`**: Cloud SQL PostgreSQL instance in `READY` state, branch `workshop_3_cloud_sql`.
- **`does`**:
  - **Phase 3A (The Naive Test)**: Create DB `rails_production` and user `rails_user`. Add authorized network `0.0.0.0/0` and test direct public connection. Discuss the security disaster of exposing port 5432 to the world.
  - **Phase 3B (The Cloud SQL Auth Proxy Fix)**: Remove `0.0.0.0/0`, run `cloud-sql-proxy` locally on `127.0.0.1:5432`, and run database migrations & seeds through the secure IAM tunnel.
- **`wow`**: Refreshing `localhost:3000` shows a new seeded post: *"🐘 Welcome to Cloud SQL!"* loaded live from the cloud database via the secure IAM proxy!
- **`creates`**: Database schema migrated to Cloud SQL via secure localhost proxy.

---

### Step 4: `workshop_4_secret_manager` (Google Cloud Secret Manager)
- **`needs`**: Step 3 completed, branch `workshop_4_secret_manager`.
- **`does`**:
  - Push `config/master.key` and database password to Google Secret Manager (`rails-master-key`, `rails-db-password`).
  - Verify secret retrieval directly via `gcloud secrets versions access latest --secret=rails-master-key`.
  - Configure runtime IAM service account roles (`roles/secretmanager.secretAccessor`).
- **`wow`**: Sensitive credentials are encrypted and verified via CLI with zero plain-text secrets in git!
- **`creates`**: Encrypted secrets stored in GCP, eliminating plain-text secrets and `.env` leaks.

---

### Step 5: `workshop_5_cloud_run_classic` (Multi-Container Cloud Run & Docker Compose)
- **`needs`**: Secrets & DB provisioned, branch `workshop_5_cloud_run_classic`.
- **`does`**:
  - Introduce the 3-container architecture (`compose.prod.yaml`):
    1. `web`: Rails Puma server on port 8080.
    2. `worker`: Solid Queue processor (`bundle exec rails solid_queue:start`).
    3. `cloudsql-proxy`: Official proxy container (`gcr.io/cloud-sql-connectors/cloud-sql-proxy:2`).
  - Test locally with `docker compose -f compose.prod.yaml up` and deploy multi-container service to Cloud Run.
- **`wow`**: The entire 3-container production stack (Web + Worker + Auth Proxy sidecar) boots with one command and deploys live to Cloud Run!
- **`creates`**: Production multi-container Rails 8 application running live on Cloud Run.

---

### Step 6: `workshop_6_cloud_build_cicd` (Automating with Cloud Build - *Optional / Skippable*)
- **`needs`**: Live Cloud Run service, branch `workshop_6_cloud_build_cicd`.
- **`does`**:
  - Inspect `cloudbuild.yaml` automated pipeline (Build, Migrate DB, Deploy to Cloud Run).
  - (Optional) Configure GitHub Cloud Build Trigger and verify automatic deployment on `git push`.
- **`wow`**: Every `git push` automatically tests, builds, migrates, and deploys the app to Cloud Run!
- **`creates`**: Automated CI/CD pipeline on Google Cloud (can be skipped to jump straight to AI features).

---

### Step 7: `workshop_7_ai_features` (AI Background Jobs with Solid Queue & Gemini 🍌)
- **`needs`**: Step 5 (or Step 6) completed, `GEMINI_API_KEY` in Secret Manager, branch `workshop_7_ai_features`.
- **`does`**:
  - Implement **NanoBanana Auto-Cover Generator** (`GenerateCoverImageJob`): generates vintage Italian poster art with a banana via Gemini/Imagen and attaches it via ActiveStorage.
  - (Bonus) Implement **Podcastifier**: Translates post to Italian and synthesizes `.mp3` audio via Cloud Text-to-Speech.
- **`wow`**: Publishing a post with no cover image automatically generates a custom 1960s Italian movie poster with a cameo banana in real-time!
- **`creates`**: Intelligent, asynchronous AI features powered by Solid Queue workers.

---

## Post-Story Implementation Checklist

- [ ] `workshop_1_local_baseline` branch verified
- [ ] `workshop_2_cloud_storage` branch verified
- [ ] `workshop_3_cloud_sql` branch verified (includes Auth Proxy local config)
- [ ] `workshop_4_secret_manager` branch verified
- [ ] `workshop_5_cloud_run_classic` branch verified (includes `compose.prod.yaml`)
- [ ] `workshop_6_cloud_build_cicd` branch verified (optional track)
- [ ] `workshop_7_ai_features` branch verified
