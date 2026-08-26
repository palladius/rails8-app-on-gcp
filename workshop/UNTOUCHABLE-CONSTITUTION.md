# 📜 Rails 8 on GCP Workshop Constitution & Architectural Blueprint
> **STATUS: 🟡 DRAFT (v2)** (Revised with Dual North Stars).  
> Once finalized and approved by Riccardo & Emiliano, this document serves as the **UNTOUCHABLE CONSTITUTION** governing `main`, workshop branches, `CODELAB.md`, `SKELETON.md`, automation scripts, and visualizers.

---

## 🎯 1. Mission & The Dual North Stars

This project is bifidus and achieves two equally crucial strategic goals:

### 🌟 North Star 1: The Canonical "Rails 8 on GCP" Production Blueprint (`main`)
1. **The Destination:** `main` in this repository is the complete, working, battle-tested, editable reference architecture ("The Gold Standard") for running Rails 8 on Google Cloud Platform.
2. **Blueprint Capabilities:**
   - Managed PostgreSQL on **Cloud SQL** with connection pooling.
   - Private **Google Cloud Storage** with IAM Credential blob signing (`iam: true` / zero public buckets).
   - Enterprise credential management via **Google Cloud Secret Manager**.
   - Production multi-container sidecar topology on **Cloud Run** (`web` + `worker` Solid Queue + `cloudsql-proxy` sidecar).
   - Automated CI/CD pipelines via **Cloud Build**.
   - Asynchronous Generative AI background pipelines (Gemini / Imagen auto-cover generation & audio podcast synthesis).
3. **Branching Model:** `main` contains the full end-state blueprint. The `workshop_*` branches provide progressive, curated stepping stones that build up to `main`.

---

### 🌟 North Star 2: The Universal Developer Workshop (GCP & Antigravity for Everyone)
1. **The Audience Reality:** While launching at a Ruby conference (Oct 2), **~90% of future workshop attendees will have zero Ruby background**. They are developers, SREs, and cloud practitioners eager to learn Google Cloud, serverless architecture, and modern AI development.
2. **Pedagogical Mandate:**
   - **Zero Language Friction:** Never let Ruby syntax or Rails idiosyncrasies block an attendee. App commands are standardized (`bin/dev`, `bin/rails db:...`).
   - **Antigravity as Co-Pilot:** Use **Google Antigravity** as the universal pair programmer to inspect the codebase, explain architecture, generate Mermaid diagrams, and debug issues in real-time.
   - **Cloud-First Teachable Moments:** Focus on real cloud problems—statelessness, security anti-patterns (why `0.0.0.0/0` and public buckets are dangerous), IAM tunneling with Cloud SQL Auth Proxy, sidecar orchestration, and async AI workers.
   - **Dual Track Flexibility:** Full Cloud Track (with billing & Cloud SQL) vs. **Zero-Billing Free Track** (SQLite on Cloud Run + Gemini Free Tier API Key).

---

## 👥 2. Personas & Workshop Conventions

- **Riccardo:** Supreme Leader and pun-master 🦖
- **Emiliano:** Al Mudnais cal'scorda i symlink 🍝🏎️
- **Theme & Branding:** Colorful, vibrant Google branding featuring the vintage Italian "NanoBanana" mascot 🍌.
- **Tone:** Technically rigorous, engaging, and welcoming to developers of all backgrounds.

---

## 🏛️ 3. The 5-Part Step Contract

Every chapter in the workshop adheres to the **Enhanced Step Contract**:
$$\text{Step} = \langle \text{needs}, \text{does}, \text{antigravity}, \text{wow}, \text{creates} \rangle$$

```
┌─────────────────────────────────────────────────────────────┐
│ 1. PREREQUISITES (needs)                                    │
│    - Git branch checkpoint                                  │
│    - CLI tools / IAM permissions / Background state         │
├─────────────────────────────────────────────────────────────┤
│ 2. ACTIONS & TEACHABLE MOMENTS (does)                       │
│    - Concrete code/config modifications                     │
│    - Anti-patterns explored & corrected (e.g. 0.0.0.0/0)    │
├─────────────────────────────────────────────────────────────┤
│ 3. ANTIGRAVITY CO-PILOT (antigravity) 🤖                     │
│    - AI pair programming prompts for non-Rubyists           │
│    - Codebase exploration & automated diagram generation    │
├─────────────────────────────────────────────────────────────┤
│ 4. THE AHA! / WOW MOMENT (wow) ✨                           │
│    - Visual & sensory proof of working cloud technology     │
├─────────────────────────────────────────────────────────────┤
│ 5. DELIVERABLES (creates)                                   │
│    - Verified milestone towards the `main` blueprint        │
└─────────────────────────────────────────────────────────────┘
```

---

## 🗺️ 4. Master Step Breakdown

```mermaid
flowchart TD
    S0["Step 0: Setup & Async Cloud Launch<br/>(Terraform / provision script started in background)"] --> S1["Step 1: The Local Baseline<br/>(Local app + Antigravity ER diagram discovery)"]
    S1 --> S2["Step 2: Cloud Storage (ActiveStorage + GCS)<br/>(Private bucket + IAM signing + Live drop)"]
    S2 --> S3A["Step 3A: The Naive DB Connection<br/>(0.0.0.0/0 test & Security breakdown)"]
    S3A --> S3B["Step 3B: Local Cloud SQL Auth Proxy<br/>('Welcome to Cloud SQL' seeded post via IAM)"]
    S3B --> S4["Step 4: Secret Manager<br/>(RAILS_MASTER_KEY & DB credentials via gcloud)"]
    S4 --> S5["Step 5: Multi-Container Cloud Run<br/>(Web + SolidQueue Worker + Cloud SQL Proxy)"]
    S5 -.->|Optional / Skippable| S6["Step 6: CI/CD with Cloud Build<br/>(cloudbuild.yaml + Git Trigger)"]
    S5 --> S7["Step 7: AI Features with Solid Queue<br/>(NanoBanana Cover Generator + Podcastifier)"]
    S6 --> S7
    S7 ==> MAIN["🏆 The 'main' Blueprint Reached!"]
```

---

### 🔹 Step 0: Setup & Async Cloud Provisioning
- **`needs`**: 
  - GCP project (Billing enabled for Cloud SQL track, or Free Tier for Zero-Billing track).
  - CLI tools: `gcloud`, `ruby` 3.3+, `gem install rails`, `terraform`, `docker`, and `cloud-sql-proxy`.
  - Google Antigravity IDE or VS Code Antigravity Extension.
- **`does`**:
  - Clones the workshop repository.
  - Authenticates `gcloud auth login` and `gcloud auth application-default login`.
  - **IMMEDIATELY kicks off Cloud SQL & GCS provisioning** in the background (`./bin/provision-cloudsql.sh` or `cd iac && terraform apply`).
  - *(Zero-Billing Track alternative: skips Cloud SQL provisioning and uses SQLite on Cloud Run + Gemini Free Tier)*.
- **`antigravity`**: Use Antigravity to verify environment prerequisites and active GCP project configuration.
- **`wow`**: One command starts heavy cloud provisioning asynchronously without blocking the student's workflow!
- **`creates`**: Background infrastructure cooking in GCP (~10-12 mins) while students proceed immediately to Step 1.

---

### 🔹 Step 1: The Local Baseline (Exploration for Rubyists & Non-Rubyists)
- **`needs`**: Step 0 completed, branch `workshop_1_local_baseline`.
- **`does`**:
  - Runs `bundle install`, `bin/rails db:setup`, and `bin/dev`.
  - Opens `http://localhost:3000`, logs in with seeded credentials (`riccardo@example.com` / `Ch4ng3m3!!1`).
  - Creates a new blog post and drags-and-drops an image directly into the ActionText / Trix rich-text editor.
- **`antigravity`**: Prompt Antigravity:
  > *"Analyze this Rails 8 application and generate a Mermaid diagram explaining how Posts, Comments, and ActiveStorage models connect."*
  *(Gives non-Rubyists instant architectural clarity!)*
- **`wow`**: Full web app running locally in <2 minutes with rich-text drag-and-drop image uploads out of the box.
- **`creates`**: Verified local baseline and clear motivation for cloud-native persistence (explaining why stateless containers wipe local SQLite/disk storage).

---

### 🔹 Step 2: Cloud Storage (ActiveStorage + GCS)
- **`needs`**: GCS Bucket provisioned from Step 0, branch `workshop_2_cloud_storage`.
- **`does`**:
  - Configures `config/storage.yml` with the `google` service and `iam: true`.
  - Sets `config.active_storage.service = :google` in `config/environments/production.rb` (and `development.rb`).
  - **Teachable Moment:** Explains why `public: true` / `allUsers` is a dangerous security trap; shows how IAM Credentials API signs private expiring blob URLs on the fly.
  - Drag-and-drops an image into the editor; inspects the network request and GCS Console to see the blob stream directly to the cloud.
- **`antigravity`**: Prompt Antigravity to review `storage.yml` and explain how Google Cloud IAM signs blob URLs without requiring private key JSON files.
- **`wow`**: Dragging and dropping an image in the browser auto-uploads directly to a private Google Cloud Storage bucket with expiring signed URLs!
- **`creates`**: Working ActiveStorage integration with private GCS bucket.

---

### 🔹 Step 3: Cloud SQL (From Naive Exposure to Auth Proxy)
- **`needs`**: Cloud SQL PostgreSQL instance ready (`READY` state from Step 0), branch `workshop_3_cloud_sql`.
- **`does`**:
  #### Phase 3A: The Naive Connection (The `0.0.0.0/0` Anti-Pattern)
  1. Creates database (`rails_production`) and user (`rails_user`).
  2. Adds authorized network `0.0.0.0/0` with a password.
  3. Tests direct connection: `psql -h <PUBLIC_IP> -U rails_user -d rails_production`.
  4. **Security Breakdown:** Details why exposing database port 5432 to `0.0.0.0/0` invites botnets, port scanners, and breaches.
  #### Phase 3B: The Cloud SQL Auth Proxy Fix & Migration
  1. Removes `0.0.0.0/0` from authorized networks.
  2. Runs `cloud-sql-proxy --port 5432 $INSTANCE_CONNECTION_NAME` locally.
  3. Runs migrations & seeds through the secure IAM tunnel:
     ```bash
     DATABASE_URL=postgresql://rails_user:$DB_PASS@127.0.0.1:5432/rails_production bin/rails db:migrate db:seed
     ```
- **`antigravity`**: Prompt Antigravity:
  > *"Explain how the Cloud SQL Auth Proxy establishes an encrypted mTLS tunnel using Application Default Credentials (ADC) without requiring firewall openings."*
- **`wow`**: Refreshing `http://localhost:3000` shows a new seeded post: *"🐘 Welcome to Cloud SQL!"* loaded live from the cloud database through the secure IAM proxy!
- **`creates`**: Migrated PostgreSQL schema on Cloud SQL and verified local proxy connection.

---

### 🔹 Step 4: Secret Management (Google Cloud Secret Manager)
- **`needs`**: Step 3 completed, branch `workshop_4_secret_manager`.
- **`does`**:
  - Explains the critical danger of storing credentials in git or `.env` files.
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
- **`antigravity`**: Ask Antigravity to audit the repository for plain-text secrets and generate the least-privilege IAM binding commands.
- **`wow`**: Sensitive secrets are encrypted and verified via CLI with zero plain-text files in git!
- **`creates`**: Centralized, encrypted secrets in Secret Manager ready for container injection.

---

### 🔹 Step 5: Multi-Container Orchestration (Docker Compose & Cloud Run)
- **`needs`**: Secrets and DB ready, branch `workshop_5_cloud_run_classic`.
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
- **`antigravity`**: Prompt Antigravity:
  > *"Explain how multi-container sidecars work on Cloud Run and how the web and worker containers communicate with the Cloud SQL proxy container on port 5432."*
- **`wow`**: The entire 3-container production stack boots locally with one Docker Compose command and deploys live to Cloud Run with zero architectural drift!
- **`creates`**: Production Rails 8 application live on Cloud Run with segregated web and worker processes.

---

### 🔹 Step 6: Automated CI/CD with Cloud Build *(Optional / Skippable)*
- **`needs`**: Working Cloud Run deployment from Step 5, branch `workshop_6_cloud_build_cicd`.
- **`does`**:
  - Inspects `cloudbuild.yaml` multi-step pipeline (Test -> Build Image -> Database Migrate Job -> Cloud Run Deploy).
  - (Optional) Configures Cloud Build Trigger connected to GitHub.
  - Pushes a commit to `main` and monitors live build logs in GCP Console.
- **`antigravity`**: Ask Antigravity to explain the Cloud Run Job migration step in `cloudbuild.yaml`.
- **`wow`**: Every `git push` automatically tests, builds, migrates, and deploys the app to Cloud Run!
- **`creates`**: Automated CI/CD pipeline on Google Cloud (can be skipped to jump straight to AI features).

---

### 🔹 Step 7: AI Features with Solid Queue & Gemini 🍌
- **`needs`**: Step 5 (or Step 6) completed, `GEMINI_API_KEY` in Secret Manager, branch `workshop_7_ai_features`.
- **`does`**:
  - Implements **NanoBanana Cover Generator** (`GenerateCoverImageJob`):
    - Submits post content to Imagen/Gemini with the vintage Italian poster prompt ("must include a banana").
    - Worker downloads generated image and attaches it via ActiveStorage.
  - (Optional / Bonus) Implements **Podcastifier**:
    - Translates post to Italian and synthesizes `.mp3` audio using Google Cloud Text-to-Speech.
- **`antigravity`**: Use Antigravity to customize the prompt engineering and test the AI worker locally before triggering it in production.
- **`wow`**: Publishing a post with no cover image automatically generates a custom 1960s Italian movie poster with a cameo banana in the background in real-time!
- **`creates`**: 🏆 **The Complete 'main' Blueprint Architecture Achieved!**

---

## 🛟 5. Fallbacks & Escape Hatches

| Challenge | Fallback Mechanism |
|---|---|
| Non-Rubyist needs syntax explanation | Antigravity AI pair programmer provides instant analogies (e.g. ActiveRecord $\approx$ Prisma/Django ORM). |
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
