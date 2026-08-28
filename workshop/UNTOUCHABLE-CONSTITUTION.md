# 📜 Rails 8 on GCP Workshop Constitution & Architectural Blueprint
> **STATUS: 🟡 DRAFT (v2)** (Revised with Dual North Stars & Exact 1:1 Master Index).  
> Once finalized and approved by Riccardo & Emiliano, this document serves as the **UNTOUCHABLE CONSTITUTION** governing `main`, workshop branches, `CODELAB.md`, `SKELETON.md`, automation scripts, and visualizers.

---

## 🗺️ 1. Executive Summary & Master Step Index

This workshop takes any developer—whether an experienced Rubyist (10%) or a cloud practitioner with zero Ruby background (90%)—from zero to a production-grade **Rails 8 on Google Cloud** deployment using **Google Antigravity** as an AI pair programmer. 

```mermaid
flowchart TD
    S0["Step 0: Setup & Async Cloud Launch<br/>(branch: workshop_0_setup)"] --> S1["Step 1: The Local Baseline<br/>(branch: workshop_1_local_baseline)"]
    S1 --> S2["Step 2: Cloud Storage<br/>(branch: workshop_2_cloud_storage)"]
    S2 --> S3["Step 3: Cloud SQL (Naive to Proxy)<br/>(branch: workshop_3_cloud_sql)"]
    S3 --> S4["Step 4: Secret Manager<br/>(branch: workshop_4_secret_manager)"]
    S4 --> S5["Step 5: Cloud Run Multi-Container<br/>(branch: workshop_5_cloud_run_multi_container)"]
    S5 -.->|Optional CI/CD| S6["Step 6: Cloud Build<br/>(branch: workshop_6_cloud_build_cicd)"]
    S5 --> S7["Step 7: AI Features with Solid Queue<br/>(branch: workshop_7_ai_features)"]
    S6 --> S7
    S7 ==> S8["Step 8 / Main: The Gold Standard Blueprint<br/>(branch: main)"]
```

### 📐 Master Step Directory (Exact 1:1 Index)

* **`workshop_0_setup` (Step 0 — Environment, GCP Auth & Async Infrastructure Launch):** The student verifies their development environment (`gcloud`, `ruby`, `terraform`, `docker`), authenticates against Google Cloud with Application Default Credentials (ADC), and immediately launches the background Cloud SQL and GCS provisioning script (`bin/provision-cloudsql.sh`) so infrastructure builds asynchronously in ~10–12 minutes without blocking local development.

* **`workshop_1_local_baseline` (Step 1 — Local Rails Baseline, Docker Compose & Email Catcher):** The student launches the local Docker Compose development stack (`web`, `worker`, `db`, `mailpit`, `db-admin`), creates an admin user with their own email address, verifies the confirmation email in the **Mailpit** web UI (port 8025), inspects database tables in **Adminer** (port 8081), and prompts Google Antigravity to analyze the codebase and generate an architectural Mermaid diagram explaining ActiveRecord models and Solid Queue.

* **`workshop_2_cloud_storage` (Step 2 — Cloud Storage with ActiveStorage & IAM Signed URLs):** The student replaces local disk storage with Google Cloud Storage (`config/storage.yml`), configures `iam: true` for zero-public-bucket security, discovers why stateless containers require cloud blob storage, and verifies that dragged-and-dropped images stream directly to private GCS with expiring signed URLs.

* **`workshop_3_cloud_sql` (Step 3 — Cloud SQL PostgreSQL from Naive 0.0.0.0/0 to Auth Proxy):** The student demonstrates the naive database anti-pattern by opening Cloud SQL to `0.0.0.0/0`, explores why this creates critical security vulnerabilities, replaces it with an encrypted mTLS tunnel using the local Cloud SQL Auth Proxy on port 5432, and migrates the schema to reveal a seeded *"🐘 Welcome to Cloud SQL!"* post.

* **`workshop_4_secret_manager` (Step 4 — Centralized Credentials with Google Secret Manager):** The student eliminates plain-text `.env` and `master.key` files from source control by uploading secrets to Google Cloud Secret Manager via `gcloud`, configures least-privilege IAM access for runtime service accounts, and verifies secret retrieval via CLI.

* **`workshop_5_cloud_run_multi_container` (Step 5 — Cloud Run Multi-Container Sidecar Orchestration):** The student transitions from local Docker Compose to Emiliano's 3-container production architecture (`compose.prod.yaml`) uniting the Puma `web` server (port 8080), the Solid Queue `worker`, and the official `cloudsql-proxy` sidecar container into a cohesive stack, tests the topology locally, and deploys it live to Google Cloud Run with zero architectural drift.

* **`workshop_6_cloud_build_cicd` (Step 6 — Automated CI/CD Pipelines with Cloud Build *[Optional]*):** The student configures a complete automated build, test, database migration, and deployment pipeline in `cloudbuild.yaml`, connects it to a Git trigger, and observes automated serverless rollouts on every push to `main` (skippable for fast-track AI exploration).

* **`workshop_7_ai_features` (Step 7 — Asynchronous Generative AI Background Jobs & Solid Queue):** The student integrates Gemini and Imagen via Solid Queue background jobs, testing the **NanoBanana Cover Generator** (which auto-synthesizes a vintage 1960s Italian poster with a cameo banana whenever a post is published) and an optional audio **Podcastifier** job using Google Cloud Text-to-Speech.

* **`main` (Step 8 — The Canonical Gold Standard Production Blueprint):** The student inspects the fully assembled, editable reference architecture on `main`, verifying production readiness, connection pooling, IAM security hardening, automated telemetry, and full parity between local Docker Compose and serverless Google Cloud Run.

---

### 🎨 Visual Architecture & Diagram Generation Prompts

To ensure consistent diagrams across codelab pages and slides, use the following verbatim prompts with **NanoBanana / Imagen 3 / Gemini**:

#### 🖼️ Prompt 1: Production Multi-Container Architecture Diagram (Verbatim)
```text
A high-resolution, modern Google Cloud serverless architecture diagram on an elegant dark slate glassmorphic background with glowing neon accents. Shows a Google Cloud Run service with three interconnected sidecar containers: (1) a Ruby on Rails 8 Puma web server container on port 8080, (2) a Solid Queue background worker container executing asynchronous AI jobs, and (3) an official Cloud SQL Auth Proxy sidecar container communicating over localhost port 5432. Demonstrates the proxy establishing an encrypted mTLS tunnel to a managed Google Cloud SQL PostgreSQL instance, the web app uploading private blobs to Google Cloud Storage signed via IAM Credentials API, secret injection from Google Cloud Secret Manager, and async jobs calling Gemini 2.5 and Imagen 3. Clean vector isometric iconography, Google blue, green, yellow, red color scheme, labeled interfaces, ultra-crisp typography.
```
![Google Cloud Run Multi-Container Architecture](assets/cloud_run_multi_container_architecture.jpg)

#### 🖼️ Prompt 2: Entity-Relationship & Database Model Schema (Verbatim)
```text
An Entity-Relationship (ER) diagram rendered in a sleek modern tech dashboard style. Demonstrates Rails 8 ActiveRecord models: 'User' (email, password_digest, role) has many 'Posts' and 'Comments'; 'Post' (title, body with ActionText rich text, slug, published_at, user_id) has many 'Comments' and ActiveStorage attachments for 'cover_image' and 'podcast_audio'; 'Comment' (body, user_id, post_id); and Solid Queue system tables ('solid_queue_jobs', 'solid_queue_processes', 'solid_queue_ready_executions'). Clean connecting foreign key arrows, glowing blue relation links, polished tech typography on a frosted glass card.
```
![Rails 8 ActiveRecord Schema & Solid Queue Architecture](assets/rails8_active_record_schema.jpg)

#### 🖼️ Prompt 3: Gemini Image Generation Pipeline (Codename: Nano Banana / Imagen 3) (Verbatim)
```text
A high-tech conceptual illustration of Google's Gemini multimodal image generation pipeline (codename 'Nano Banana' / Imagen 3). On the left, a stream of glowing code and text representing a Rails blog article flows into a glowing multi-modal Gemini AI neural engine. In the center, the neural network processes text embeddings with glowing cyan, electric blue, and golden amber light rays. On the right, it synthesizes photorealistic, high-resolution blog cover art and posters in real time. Sleek glassmorphic dark-mode UI, floating neural nodes, holographic interface elements, crisp vector tech aesthetics.
```
![Gemini Nano Banana AI Image Pipeline](assets/nanobanana_ai_image_pipeline.jpg)

#### 🖼️ Prompt 4: Google Cloud Storage & IAM Signed URLs Direct Upload (Verbatim)
```text
A visual explanation diagram of Google Cloud Storage with Rails ActiveStorage and IAM Credential signed URLs. Shows a user's browser direct-uploading an image blob to a private Google Cloud Storage bucket with a lock icon. Shows Rails requesting a short-lived signed URL from Google Cloud IAM Credentials API instead of world-readable public access. Dark glassmorphic background with Google Cloud blue and green highlights, security shield icon, clear arrows, crisp tech typography.
```
![Google Cloud Storage with Rails ActiveStorage IAM Signed URLs](assets/gcs_iam_signing_diagram.jpg)

#### 🖼️ Prompt 5: Cloud SQL 0.0.0.0/0 Anti-Pattern vs Secure Auth Proxy (Verbatim)
```text
A cybersecurity comparison infographic comparing two database connection methods. Left side labeled 'NAIVE ANTI-PATTERN (0.0.0.0/0)' showing red warning shields, exposed port 5432, and hacker botnets scanning public IP. Right side labeled 'SECURE CLOUD SQL AUTH PROXY' showing an encrypted green mTLS tunnel running on localhost 5432 using IAM Application Default Credentials (ADC) with zero firewall openings. Modern dark tech UI with neon red vs neon green contrasting aesthetics.
```
![Cloud SQL Naive 0.0.0.0/0 vs Secure Cloud SQL Auth Proxy](assets/cloud_sql_proxy_comparison.jpg)

#### 🖼️ Prompt 6: Secret Manager Runtime Injection Workflow (Verbatim)
```text
A technical security diagram illustrating Google Cloud Secret Manager runtime injection into containerized Rails applications. Shows an encrypted vault unlocking 'RAILS_MASTER_KEY' and 'DATABASE_URL' credentials, securely passing them into Google Cloud Run environment variables at runtime via IAM Service Account binding, with a crossed-out red git repo showing 'NO SECRETS IN CODE OR .ENV'. Sleek isometric security icon, Google yellow and blue accents, high resolution.
```
![Secret Manager Runtime Injection Workflow](assets/secret_manager_workflow.jpg)

#### 🖼️ Prompt 7: Streamlined Cloud Build CI/CD Pipeline (Verbatim)
```text
A streamlined DevOps CI/CD pipeline infographic for Google Cloud Build. Shows a 4-stage pipeline with connected nodes: (1) Git Commit trigger, (2) Automated RSpec unit testing in container, (3) Docker image build & push to Artifact Registry, (4) Cloud Run Database Migration Job, and (5) Zero-downtime Cloud Run service rollout. Sleek dark glassmorphic UI with glowing blue and purple connection conduits, step icons, polished typography.
```
![Streamlined DevOps CI/CD Pipeline for Google Cloud Build](assets/cloud_build_pipeline.jpg)

---

## 🎯 2. Dual North Stars & Pedagogical Mandate

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

### 🌟 North Star 2: The Universal Developer Workshop (GCP & Antigravity for Everyone)
1. **The Audience Reality:** While launching at a Ruby conference (Oct 2), **~90% of future workshop attendees will have zero Ruby background**. They are developers, SREs, and cloud practitioners eager to learn Google Cloud, serverless architecture, and modern AI development.
2. **Pedagogical Mandate:**
   - **Zero Language Friction:** Never let Ruby syntax or Rails idiosyncrasies block an attendee. Standardize commands (`docker compose up`, `bin/dev`, `bin/rails db:...`).
   - **Antigravity as Co-Pilot:** Use **Google Antigravity** as the universal pair programmer to inspect the codebase, explain architecture, generate Mermaid diagrams, and debug issues in real-time.
   - **Cloud-First Teachable Moments:** Focus on real cloud problems—statelessness, security anti-patterns (why `0.0.0.0/0` and public buckets are dangerous), IAM tunneling with Cloud SQL Auth Proxy, sidecar orchestration, and async AI workers.
   - **Dual Track Flexibility:** Full Cloud Track (with billing & Cloud SQL) vs. **Zero-Billing Free Track** (SQLite on Cloud Run + Gemini Free Tier API Key).

### 🏷️ 2.3 Environmental Telemetry & UI Storytelling (Visual Pedagogical Clues)
To guide candidates through each architectural evolution, the application UI and seeded content dynamically reflect the active persistence and storage tier:
1. **Dynamic In-App Badges (Navbar / Footer):**
   - 🟡 **`[EPHEMERAL DB ⚠️]`**: Displayed when running on local Docker Compose PostgreSQL / SQLite.
   - 🟢 **`[CLOUD SQL PERSISTENT 🐘 🔒]`**: Displayed when connected to managed Google Cloud SQL via Cloud SQL Auth Proxy mTLS.
   - 🟡 **`[LOCAL DISK STORAGE ⚠️]`**: Displayed when ActiveStorage is configured for local disk.
   - 🟢 **`[GCS PRIVATE BUCKET 🪣 🔒]`**: Displayed when ActiveStorage is streaming to private Google Cloud Storage (`iam: true`).
2. **Narrative-Driven Seeded Posts:**
   - **Step 1:** `"[EPHEMERAL] ⚠️ Benvenuto! Sei su un DB locale effimero"` — *Warns the student that local container restarts will wipe data, setting up the motivation for Cloud Storage (Step 2) and Cloud SQL (Step 3).*
   - **Step 2:** `"[STORAGE CONNECTED] ☁️ ActiveStorage ora parla a Google Cloud Storage!"` — *Explains that dragged images are safely stored in private GCS buckets via IAM signed URLs.*
   - **Step 3:** `"[DATABASE PERSISTENT] 🐘 Connesso a Google Cloud SQL via Auth Proxy!"` — *Celebrates graduating from ephemeral local storage to encrypted Cloud SQL.*
   - **Step 7:** `"[AI ACTIVE] 🍌 Nano Banana / Imagen 3 Generatore di Copertine Attivo!"` — *Demonstrates asynchronous GenAI job completion.*

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

## 🔹 Step 0: Setup & Async Cloud Provisioning (`workshop_0_setup`)
- **`needs`**: 
  - GCP project (Billing enabled for Cloud SQL track, or Free Tier for Zero-Billing track).
  - CLI tools: `gcloud`, `ruby` 3.3+, `gem install rails`, `terraform`, `docker`, and `cloud-sql-proxy`.
  - Google Antigravity IDE or VS Code Antigravity Extension.
- **`does`**:
  - Clones the workshop repository.
  - Authenticates `gcloud auth login` and `gcloud auth application-default login`.
  - **IMMEDIATELY kicks off Cloud SQL & GCS provisioning** in the background (`./bin/provision-cloudsql.sh` or `cd iac && terraform apply`).
  - *(Zero-Billing Track alternative: skips Cloud SQL provisioning and uses SQLite on Cloud Run + Gemini Free Tier)*.
- **`antigravity`**: Prompt Antigravity:
  > *"Verify my GCP authentication status, active project ID, and whether gcloud ADC credentials are configured correctly for Terraform."*
- **`wow`**: One command starts heavy cloud provisioning asynchronously in GCP without blocking the student's workflow!
- **`creates`**: Background infrastructure cooking in GCP (~10-12 mins) while students proceed immediately to Step 1.

---

## 🔹 Step 1: The Local Baseline (`workshop_1_local_baseline`)
- **`needs`**: Step 0 completed, branch `workshop_1_local_baseline`.
- **`does`**:
  - Boots the development stack either natively (`bin/dev`) or via Docker Compose (`docker compose up` / `compose.yaml`).
  - **The "Benvenuto" Admin Onboarding Flow:** Opens `http://localhost:3000` and creates their initial admin user by entering **their own real email address** (e.g. `ricc@google.com` or `yourname@gmail.com`).
  - Rails immediately dispatches a personalized **"🎉 Benvenuto in Rails 8 on Google Cloud!"** HTML welcome email via ActionMailer.
  - **Email Catcher Verification:** Opens **Mailpit** at `http://localhost:8025` to inspect their own email address receiving the captured welcome email in real-time, verifying email generation and HTML templates with zero risk of external spam.
  - **Database Admin Flow:** Opens **Adminer** at `http://localhost:8081` to inspect the underlying PostgreSQL tables (`users`, `posts`, `solid_queue_jobs`).
  - Creates a new blog post and drags-and-drops an image directly into the ActionText / Trix rich-text editor.
- **`antigravity`**: Prompt Antigravity:
  > *"Analyze this Rails 8 application and generate a Mermaid diagram explaining how Users, Posts, Comments, and Solid Queue background jobs interact."*
  *(Gives non-Rubyists instant architectural clarity!)*
- **`wow`**: Entering their own email instantly triggers a personalized Italian *Benvenuto* email caught live in the local Mailpit Docker UI, alongside an in-browser database visualizer (Adminer)!
- **`creates`**: Verified local baseline and clear motivation for cloud-native persistence (explaining why stateless containers wipe local SQLite/disk storage).

---

## 🔹 Step 2: Cloud Storage with ActiveStorage & GCS (`workshop_2_cloud_storage`)
- **`needs`**: GCS Bucket provisioned from Step 0, branch `workshop_2_cloud_storage`.
- **`does`**:
  - Configures `config/storage.yml` with the `google` service and `iam: true`.
  - Sets `config.active_storage.service = :google` in `config/environments/production.rb` (and `development.rb`).
  - **Teachable Moment:** Explains why `public: true` / `allUsers` is a dangerous security trap; shows how IAM Credentials API signs private expiring blob URLs on the fly.
  - Drag-and-drops an image into the editor; inspects the network request and GCS Console to see the blob stream directly to the cloud.
- **`antigravity`**: Prompt Antigravity:
  > *"Review config/storage.yml and explain how Google Cloud IAM signs private blob URLs without requiring long-lived service account key files."*
- **`wow`**: Dragging and dropping an image in the browser auto-uploads directly to a private Google Cloud Storage bucket with expiring signed URLs!
- **`creates`**: Working ActiveStorage integration with private GCS bucket.

---

## 🔹 Step 3: Cloud SQL (Naive Exposure to Auth Proxy) (`workshop_3_cloud_sql`)
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

## 🔹 Step 4: Secret Management with Secret Manager (`workshop_4_secret_manager`)
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
- **`antigravity`**: Prompt Antigravity:
  > *"Audit our repository for any plain-text secrets and generate the least-privilege gcloud IAM binding commands for Cloud Secret Manager."*
- **`wow`**: Sensitive secrets are encrypted and verified via CLI with zero plain-text files in git!
- **`creates`**: Centralized, encrypted secrets in Secret Manager ready for container injection.

---

## 🔹 Step 5: Multi-Container Sidecars on Cloud Run (`workshop_5_cloud_run_multi_container`)
- **`needs`**: Secrets and DB ready, branch `workshop_5_cloud_run_multi_container`.
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

## 🔹 Step 6: Automated CI/CD with Cloud Build (`workshop_6_cloud_build_cicd`) *(Optional)*
- **`needs`**: Working Cloud Run deployment from Step 5, branch `workshop_6_cloud_build_cicd`.
- **`does`**:
  - Inspects `cloudbuild.yaml` multi-step pipeline (Test -> Build Image -> Database Migrate Job -> Cloud Run Deploy).
  - (Optional) Configures Cloud Build Trigger connected to GitHub.
  - Pushes a commit to `main` and monitors live build logs in GCP Console.
- **`antigravity`**: Prompt Antigravity:
  > *"Explain how the Cloud Run Job migration step works in cloudbuild.yaml and why migrations should run in an ephemeral job before container rollout."*
- **`wow`**: Every `git push` automatically tests, builds, migrates, and deploys the app to Cloud Run!
- **`creates`**: Automated CI/CD pipeline on Google Cloud (can be skipped to jump straight to AI features).

---

## 🔹 Step 7: AI Features with Solid Queue & Gemini (`workshop_7_ai_features`)
- **`needs`**: Step 5 (or Step 6) completed, `GEMINI_API_KEY` in Secret Manager, branch `workshop_7_ai_features`.
- **`does`**:
  - Implements **NanoBanana Cover Generator** (`GenerateCoverImageJob`):
    - Submits post content to Imagen/Gemini with the vintage Italian poster prompt ("must include a banana").
    - Worker downloads generated image and attaches it via ActiveStorage.
  - (Optional / Bonus) Implements **Podcastifier**:
    - Translates post to Italian and synthesizes `.mp3` audio using Google Cloud Text-to-Speech.
- **`antigravity`**: Prompt Antigravity:
  > *"Help me customize the Imagen prompt template in app/jobs/generate_cover_image_job.rb to add custom art styles while preserving the background banana cameo."*
- **`wow`**: Publishing a post with no cover image automatically generates a custom 1960s Italian movie poster with a cameo banana in the background in real-time!
- **`creates`**: 🏆 **The Complete 'main' Blueprint Architecture Achieved!**

---

## 🔹 Step 8: The Gold Standard Blueprint (`main`)
- **`needs`**: Step 7 completed, branch `main`.
- **`does`**:
  - Reviews the complete, unified production architecture on `main`.
  - Verifies connection pooling, private GCS IAM signed URLs, sidecar container health, and background worker queues.
  - Explores how to clone, modify, or fork `main` as a reference template for any enterprise Rails 8 application on Google Cloud.
- **`antigravity`**: Prompt Antigravity:
  > *"Generate a production readiness checklist for this Rails 8 on GCP blueprint, verifying IAM permissions, secret management, and Cloud Run scaling parameters."*
- **`wow`**: A modern, monolithic, single-repo Rails 8 enterprise application running serverlessly on Google Cloud with zero server maintenance!
- **`creates`**: Master reference blueprint ready for production deployment.

---

## 🛟 4. Fallbacks & Escape Hatches

| Challenge | Fallback Mechanism |
|---|---|
| Non-Rubyist needs syntax explanation | Antigravity AI pair programmer provides instant analogies (e.g. ActiveRecord $\approx$ Prisma/Django ORM). |
| No GCP Billing / Zero-Billing Track | Run SQLite mode on Cloud Run with volume mount + Gemini Free Tier API Key. |
| Cloud SQL provisioning fails or times out | Pre-warmed fallback project/instance connection string provided by instructors. |
| Docker / Proxy networking issues locally | Direct connection with environment variable overrides (`DATABASE_URL` pointing to localhost or fallback). |
| Cloud Run multi-container deploy fails | Single-container standard deploy script (`gcloud run deploy --image ...`). |
| Missing Gemini API Quota | Mock AI worker engine that returns bundled sample cover art and audio clips. |
