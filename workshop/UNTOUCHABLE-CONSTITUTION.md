# 📜 Rails 8 on GCP Workshop Constitution & Architectural Blueprint
> **STATUS: 🟡 DRAFT** (Under review by Riccardo & Emiliano).  
> Once finalized and approved, this document becomes the **UNTOUCHABLE CONSTITUTION** to which all workshop branches, `CODELAB.md`, `SKELETON.md`, automation scripts, and UI viewers must strictly adhere.

---

## 🎯 1. Workshop Mission & North Star

1. **Target Audience:** Ruby/Rails developers exploring modern deployment options, cloud practitioners, and DevOps engineers wanting a clean, production-grade Rails 8 blueprint on Google Cloud Platform.
2. **Pedagogical Flow:** Meet developers where they are (local SQLite, `bin/dev`, instant local satisfaction), incrementally introduce cloud-native primitives (Cloud Storage, Cloud SQL, Secret Manager, Cloud Run multi-container, Cloud Build), and culminate with AI-powered background jobs using Solid Queue and Gemini.
3. **Core Philosophy:**
   - **Zero Magic / Explicit Security:** No fake shortcuts that leak credentials (no public `0.0.0.0/0` in production, no world-readable GCS buckets, no `.env` files in git).
   - **Pacing Optimization:** Heavy cloud provisioning (Cloud SQL ~10–12 min) is launched asynchronously upfront so students are never sitting idle.
   - **The 4-Part Contract:** Every step must clearly define its **Prerequisites (`needs`)**, **Actions & Learnings (`does`)**, **Aha! / Wow Moment (`wow`)**, and **Outcomes (`creates`)**.
   - **Flexible Tracks:** Full Cloud Track (with billing & Cloud SQL) vs. **Zero-Billing / Free Track** (SQLite on Cloud Run + Gemini Free Tier API key, *ohne* Cloud SQL).

---

## 👥 2. Personas & Workshop Conventions

- **Riccardo:** Supreme Leader and pun-master 🦖
- **Emiliano:** Al Mudnais cal'scorda i symlink 🍝🏎️
- **Theme & Branding:** Colorful, high-energy Google branding with the "NanoBanana" mascot 🍌.
- **Tone:** Technical rigor paired with approachable, fun analogies.

---

## 🏛️ 3. The 4-Part Step Blueprint (The Enhanced Contract)

Every chapter in the workshop adheres to the **Trifecta + Wow Contract**:
$$\text{Step} = \langle \text{needs}, \text{does}, \text{wow}, \text{creates} \rangle$$

```
┌─────────────────────────────────────────────────────────────┐
│ 1. PREREQUISITES (needs)                                    │
│    - Git branch baseline                                    │
│    - CLI tools / IAM permissions / Background job state     │
├─────────────────────────────────────────────────────────────┤
│ 2. ACTIONS & TEACHABLE MOMENTS (does)                       │
│    - Concrete code/config modifications                     │
│    - Commands executed                                      │
│    - Anti-patterns explored & corrected (e.g. 0.0.0.0/0)    │
├─────────────────────────────────────────────────────────────┤
│ 3. THE AHA! / WOW MOMENT (wow) ✨                           │
│    - Visible instant gratification for the student          │
│    - Sensory/visual proof that the cloud piece works        │
├─────────────────────────────────────────────────────────────┤
│ 4. DELIVERABLES (creates)                                   │
│    - Verifiable local/remote functionality                  │
│    - Git branch checkpoint tag                              │
│    - Cloud infrastructure state                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🗺️ 4. Master Steps Walkthrough

```mermaid
flowchart TD
    S0["Step 0: Setup & Async Cloud Provisioning<br/>(Terraform / provision script + Free Track option)"] --> S1["Step 1: The Local Baseline<br/>(SQLite + RichText drag & drop + Gemini exploration)"]
    S1 --> S2["Step 2: Cloud Storage (ActiveStorage + GCS)<br/>(Private bucket + IAM signing + Live GCS drop)"]
    S2 --> S3A["Step 3A: The Naive DB Connection<br/>(0.0.0.0/0 test & Security breakdown)"]
    S3A --> S3B["Step 3B: Local Cloud SQL Auth Proxy<br/>('Welcome to Cloud SQL' seeded post appears!)"]
    S3B --> S4["Step 4: Secret Manager<br/>(RAILS_MASTER_KEY & DB credentials via gcloud)"]
    S4 --> S5["Step 5: Multi-Container Cloud Run<br/>(Web + SolidQueue Worker + Cloud SQL Proxy)"]
    S5 -.->|Optional / Skippable| S6["Step 6: CI/CD with Cloud Build<br/>(cloudbuild.yaml + Triggers)"]
    S5 --> S7["Step 7: AI Features with Solid Queue<br/>(NanoBanana Cover Generator + Podcastifier)"]
    S6 --> S7
```

---

### 🔹 Step 0: Setup & Async Cloud Provisioning
- **`needs`**: 
  - GCP project (Billing enabled for Cloud SQL track, or Free Tier for Zero-Billing track).
  - Installed CLI tools: `gcloud`, `ruby` 3.3+, `gem install rails`, `terraform`, `docker`, and `cloud-sql-proxy`.
  - Google Antigravity IDE or VS Code Antigravity Extension.
- **`does`**:
  - Clones the workshop repository.
  - Authenticates `gcloud auth login` and `gcloud auth application-default login`.
  - Verifies billing status (`gcloud billing projects describe $PROJECT_ID`).
  - **IMMEDIATELY kicks off Cloud SQL & GCS provisioning** in the background via Terraform or helper script (`./bin/provision-cloudsql.sh`).
  - *(Zero-Billing Track alternative: skips Cloud SQL provisioning and uses SQLite volume/GCS free tier)*.
- **`wow`**: One command starts heavy cloud provisioning in the background without freezing the student's terminal!
- **`creates`**: Background cloud provisioning job in progress (elapsed time: ~12 minutes).

---

### 🔹 Step 1: The Local Baseline (Instant Local Gratification)
- **`needs`**: 
  - Step 0 completed.
  - Branch: `workshop_1_local_baseline`.
- **`does`**:
  - Runs `bundle install`, `bin/rails db:setup`, and `bin/dev`.
  - Opens `http://localhost:3000`, logs in (`riccardo@example.com` / `Ch4ng3m3!!1`).
  - Creates a new blog post and uses ActionText / Trix editor to drag-and-drop a local image directly into the post body.
  - **Gemini / Antigravity Interactive Exploration:**
    - Uses Antigravity to inspect ActiveRecord models and generate a Mermaid ER diagram.
    - Discusses why local disk storage and SQLite are ephemeral in container environments.
- **`wow`**: App is fully working locally in under 2 minutes with rich-text image drag-and-drop!
- **`creates`**: Verified local baseline application running on SQLite.

---

### 🔹 Step 2: Cloud Storage with ActiveStorage & GCS
- **`needs`**: 
  - GCS Bucket provisioned from Step 0.
  - Branch: `workshop_2_cloud_storage`.
- **`does`**:
  - Configures `config/storage.yml` with the `google` service.
  - Sets `config.active_storage.service = :google` in `config/environments/production.rb` (and `development.rb`).
  - **The Teachable Moment:**
    - Configures `iam: true` in `storage.yml` to sign blob URLs via the Google IAM Credentials API without requiring static private keys.
    - Explains why `public: true` / `allUsers` is an insecure anti-pattern.
  - Drag-and-drops an image into the post editor; inspects the network tab and GCS Console to see the blob land live in the cloud.
- **`wow`**: Drag-and-dropping an image into the Rails editor now uploads directly to a private Google Cloud Storage bucket with expiring signed URLs!
- **`creates`**: Working ActiveStorage integration uploading to private GCS with short-lived signed URLs.

---

### 🔹 Step 3: Cloud SQL — From Naive Exposure to Secure Auth Proxy
- **`needs`**: 
  - Cloud SQL PostgreSQL instance ready (`READY` state from Step 0).
  - Branch: `workshop_3_cloud_sql`.
- **`does`**:
  #### Phase A: The Naive Connection (The `0.0.0.0/0` Anti-Pattern)
  1. Creates database (`rails_production`) and user (`rails_user`).
  2. Adds authorized network `0.0.0.0/0` with a password.
  3. Tests direct connection: `psql -h <PUBLIC_IP> -U rails_user -d rails_production`.
  4. **Security Breakdown:** Details why exposing port 5432 to `0.0.0.0/0` invites port scanners, brute-force bots, and breaches.
  #### Phase B: The Cloud SQL Auth Proxy Fix & Migration
  1. Removes `0.0.0.0/0` from authorized networks.
  2. Runs `cloud-sql-proxy --port 5432 $INSTANCE_CONNECTION_NAME` on localhost.
  3. Runs database migration & seed through the secure IAM tunnel:
     ```bash
     DATABASE_URL=postgresql://rails_user:$DB_PASS@127.0.0.1:5432/rails_production bin/rails db:migrate db:seed
     ```
  4. Launches local server pointing to Cloud SQL.
- **`wow`**: Refreshing `http://localhost:3000` reveals a new seeded post: *"🐘 Welcome to Cloud SQL!"* loaded live from the managed cloud database through the secure IAM proxy!
- **`creates`**: Migrated PostgreSQL schema on Cloud SQL and verified local proxy connection.

---

### 🔹 Step 4: Secret Management (Google Cloud Secret Manager)
- **`needs`**: 
  - Step 3 completed.
  - Branch: `workshop_4_secret_manager`.
- **`does`**:
  - Explains the danger of committing `.env` or master keys to git.
  - Pushes `config/master.key` and DB credentials to Google Secret Manager:
    ```bash
    gcloud secrets create rails-master-key --data-file=config/master.key
    gcloud secrets create rails-db-password --data-file=<(echo -n "$DB_PASSWORD")
    ```
  - Verifies retrieval directly via CLI:
    ```bash
    gcloud secrets versions access latest --secret=rails-master-key
    ```
  - Grants Secret Accessor IAM roles to the runtime service account.
- **`wow`**: Secrets are safely retrieved from Google Cloud Secret Manager with zero plain-text files in git!
- **`creates`**: Centralized, encrypted secrets in Secret Manager ready for container injection.

---

### 🔹 Step 5: Multi-Container Orchestration (Docker Compose & Cloud Run)
- **`needs`**: 
  - Secrets and DB ready.
  - Branch: `workshop_5_cloud_run_classic`.
- **`does`**:
  - Introduces Emiliano's 3-container architecture (`compose.prod.yaml`):
    1. `web`: Rails Puma server on port 8080.
    2. `worker`: Solid Queue processor running `bundle exec rails solid_queue:start`.
    3. `cloudsql-proxy`: Sidecar container (`gcr.io/cloud-sql-connectors/cloud-sql-proxy:2`).
  - Tests the full stack locally via `docker compose -f compose.prod.yaml up`.
  - Deploys the multi-container configuration to Google Cloud Run:
    ```bash
    gcloud run deploy rails-blog --source . --region us-central1 ...
    ```
- **`wow`**: The entire 3-container production stack (Web + Background Worker + Cloud SQL Proxy sidecar) boots with a single command and deploys live to Cloud Run!
- **`creates`**: Production Rails 8 application live on Cloud Run with segregated web and worker processes.

---

### 🔹 Step 6: Automated CI/CD with Cloud Build *(Optional / Skippable)*
- **`needs`**: 
  - Working Cloud Run deployment from Step 5.
  - Branch: `workshop_6_cloud_build_cicd`.
- **`does`**:
  - Inspects `cloudbuild.yaml` multi-step pipeline (Test -> Build Image -> Database Migrate Job -> Cloud Run Deploy).
  - (Optional) Configures Cloud Build Trigger connected to GitHub.
  - Pushes a commit to `main` and monitors live build logs in GCP Console.
- **`wow`**: Every `git push` automatically tests, builds, migrates, and deploys the app to Cloud Run!
- **`creates`**: Automated CI/CD pipeline on Google Cloud (can be skipped to jump straight to AI features).

---

### 🔹 Step 7: AI Features with Solid Queue & Gemini 🍌
- **`needs`**: 
  - Step 5 (or Step 6) completed.
  - Branch: `workshop_7_ai_features`.
  - `GEMINI_API_KEY` stored in Secret Manager.
- **`does`**:
  - Implements **NanoBanana Cover Generator** (`GenerateCoverImageJob`):
    - Submits post content to Imagen/Gemini with the vintage Italian poster prompt ("must include a banana").
    - Worker downloads generated image and attaches it via ActiveStorage.
  - (Optional / Bonus) Implements **Podcastifier**:
    - Translates post to Italian and synthesizes `.mp3` audio using Google Cloud Text-to-Speech.
- **`wow`**: Publishing a post with no cover image automatically generates a custom 1960s Italian movie poster with a cameo banana in the background in real-time!
- **`creates`**: Intelligent, asynchronous AI capabilities running seamlessly on background workers.

---

## 🛟 5. Fallbacks & Escape Hatches

| Challenge | Fallback Mechanism |
|---|---|
| No GCP Billing / Zero-Billing Track | Run SQLite mode on Cloud Run with volume mount + Gemini Free Tier API Key. |
| Cloud SQL provisioning fails or times out | Pre-warmed fallback project/instance connection string provided by instructors. |
| Docker / Proxy networking issues locally | Direct connection with environment variable overrides (`DATABASE_URL` pointing to localhost or fallback). |
| Cloud Run multi-container deploy fails | Single-container standard deploy script (`gcloud run deploy --image ...`). |
| Missing Gemini API Quota | Mock AI worker engine that returns bundled sample cover art and audio clips. |

---

## 🔒 6. Governance & Modification Rules

1. Any proposed modification to workshop narrative or step order **must first be updated in this file**.
2. Once this file is marked **🟢 FINAL**, `SKELETON.md` and `CODELAB.md` must be regenerated to reflect it 1:1.
3. Automated test scripts (`just test` / `split_codelab.rb`) must pass before commits are finalized.
