<!-- ⚠️ AGENT WARNING: This file (CODELAB.md) and SKELETON.md must be kept in sync at all times. A change to one requires a change to the other! -->
<!-- 📜 Adheres to docs/CONSTITUTION.md (v1.1.0) -->
<!-- 🏷️ Codelab Version: 2.0.1alpha -->
# Rails 8 on Google Cloud: From Zero to AI

## Introduction

*Duration: 5min*

![Rails on Google Cloud](assets/images/rails_gcp_logo.jpg)

Welcome to the **Rails 8 on Google Cloud** workshop (v2.0.1alpha)! In this hands-on codelab, you will take a modern Rails 8 application from a simple local SQLite baseline to a production-grade, enterprise-ready reference architecture on Google Cloud.

This curriculum is structured around the **3 Progressive Cloud Run Deployments**, the **Zero-Branch Time-Machine** progression model, and AI pair programming with **Google Antigravity**:
1. **Deploy 1 (Step 3 - The Stateless Shock):** Deploy a single container with local SQLite to experience serverless statelessness first-hand in under 3 minutes.
2. **Deploy 2 (Step 4 - GCS Persistent Storage):** Wire ActiveStorage to Google Cloud Storage with private IAM Credentials blob signing (`iam: true`) and observe the POLA stuck jobs warning banner.
3. **Deploy 3 (Step 6 - Gold Standard Multi-Container Sidecars):** Deploy the canonical production architecture with Puma web, Solid Queue worker, and Cloud SQL Auth Proxy sidecar containers connecting to managed PostgreSQL.

### What you'll learn
- How to pair-program with Google Antigravity to demystify Rails 8 and Google Cloud.
- How to run automated pre-flight diagnostics (`just workshop-test`) and test stages in isolated clones (`just workshop-uat`).
- How to transition configurations seamlessly without branch confusion using `just workshop-rewind` and `just workshop-restore-gold`.
- How to provision Google Cloud infrastructure asynchronously using Terraform while continuing local development without blocking.
- How to eliminate security anti-patterns: private GCS buckets (`iam: true`) and Cloud SQL Auth Proxy mTLS tunnels instead of opening `0.0.0.0/0`.
- How to inject secrets directly from Google Cloud Secret Manager.
- How to orchestrate asynchronous GenAI background jobs (NanoBanana cover generator, bilingual podcast synthesis) via Solid Queue.

> 🐝 **Live Workshop Telemetry & Leaderboard**  
> Se sei online e il tuo proctor sta mostrando la leaderboard, e vuoi far parte della leaderboard, aggiungi il tuo Cloud Run URL qui:  
> 👉 [**Registra il tuo Cloud Run sulla Leaderboard**](https://docs.google.com/forms/d/e/1FAIpQLSf9iN_m8O5LVMeo7Z80OTo3t0IKv_UrOgEndZDmzdB5qwBa2A/viewform)  
> *(Puoi registrarti fin da subito o appena completi il primo deploy su Cloud Run nello Step 3!)*

Let's get started!

> 🦖 **DEV TELEMETRY & WORKSHOP TRACKING:**  
> **Workshop Curriculum:** `v2.0.1alpha` (Release `v0.2.8`) | **Git Branch:** `fix-podcastifier-as-workshop-quest-v200`  
> ⚠️ *Riccardo ricordati di toglierlo prima di Modena!* Segnatevi questo commit hash nel Friction Log per correlare i test.

## Step 0: Prerequisites, Antigravity Setup & Billing Verification

*Duration: 10min*

> 💡 **The Scenario:** You and your team are building a mission-critical Rails 8 application. Before touching code or launching cloud resources, we must establish our toolchain, connect Google Antigravity, and verify our Google Cloud credentials and billing foundation.

### 1. Prerequisites Checklist

Before we begin, ensure you have the following tools available in your environment:
- **Git (2.30+):** (`git --version`) for version control, branching, and cloning the repository.
- **Google Cloud SDK (`gcloud` CLI):** Installed and up to date.
- **Terraform CLI (1.5+):** For declarative infrastructure provisioning.
- **Docker & Docker Compose:** Installed and running locally.
- **Ruby 3.3+ & Rails 8:** (`ruby -v`, `rails -v`).
- **Google Antigravity IDE / Gemini CLI:** Your autonomous AI pair programming assistant ([Download Google Antigravity](https://antigravity.google/download)).

### 2. Google Cloud Authentication, Dedicated Configuration & ADC

To prevent collisions with existing corporate, personal, or multi-account gcloud setups, we strongly recommend creating a dedicated named configuration for this workshop:

```bash
# 1. Create and activate dedicated workshop configuration (Fixes Issue #38)
gcloud config configurations create rails8-on-gcp-workshop --activate 2>/dev/null || \
  gcloud config configurations activate rails8-on-gcp-workshop

# 2. Authenticate your account and Application Default Credentials (ADC)
gcloud auth login $GOOGLE_CLOUD_ACCOUNT
gcloud auth application-default login

# 3. Configure active project and region
gcloud config set project $GOOGLE_CLOUD_PROJECT
gcloud config set compute/region europe-west1
```

> 💡 **Why a Dedicated Configuration?**  
> Using `gcloud config configurations create rails8-on-gcp-workshop` isolates all CLI settings (account, quota project, default region) specifically for this workshop. When you finish, you can switch back to your normal setup anytime with `gcloud config configurations activate default`.

> 📸 **TODO(riccardo): add screenshot showing terminal output of gcloud config configurations list with active rails8-on-gcp-workshop configuration**

### 3. 🚨 Mandatory Guard Gate: GCP Billing Verification

> ⚠️ **CRITICAL GUARD GATE:** Google Cloud SQL and Cloud Run deployments require an active linked billing account or valid workshop educational credits. Checking this now prevents cryptic quota or billing failures halfway through the lab!

Run the billing verification check:
```bash
gcloud beta billing projects describe $GOOGLE_CLOUD_PROJECT
```
Ensure `billingEnabled: true` is returned. If billing is disabled, link a billing account or redeem your workshop credit coupon in the [Google Cloud Console Billing Page](https://console.cloud.google.com/billing).

> 📸 **TODO(riccardo): add screenshot showing Google Cloud Console Billing page with active linked billing account or workshop credits**

### 4. Clone the Repository & Pair with Antigravity

Clone the repository and enter the directory. Notice that we stay entirely on **`main`**:
```bash
git clone https://github.com/palladius/rails8-app-on-gcp.git
cd rails8-app-on-gcp
```

Open this directory in **Google Antigravity**. Antigravity will automatically inspect the repository, read `AGENTS.md`, and stand by as your pair programmer.

### 5. Automated Step 0 Validation

Verify that your Step 0 environment is 100% compliant with the evaluation suite:
```bash
just workshop-eval 0
```
✨ **The Wow Moment:** Antigravity and the workshop evaluation engine verify your CLI versions, Ruby environment, and ADC authentication in under 2 seconds!

## Step 1: Terraform Infrastructure Kickoff & Pre-Flight Diagnostics

*Duration: 5min*

> 💡 **The Strategy:** Managed databases like Google Cloud SQL PostgreSQL take approximately 10–12 minutes to provision. Rather than waiting idly later, we launch immutable infrastructure via Terraform **right now in the background** while we develop locally!

### 1. Run Automated Pre-Flight Diagnostics Suite

Before launching cloud infrastructure, run the comprehensive pre-flight test suite:
```bash
just workshop-test
```
This script (`bin/workshop_diagnostics.rb`):
- Verifies your `GOOGLE_CLOUD_ACCOUNT` identity configuration.
- Verifies active billing and project linkage.
- Validates Application Default Credentials (ADC) for Vertex AI.
- Confirms the ActiveStorage canary seed image (`blog/app/assets/images/gcs_dev_image.jpg`).

> 📸 **TODO(riccardo): add screenshot of 'just workshop-test' running in terminal with all-green checkmarks**

If `.env` is missing, copy it from the documented template:
```bash
cp .env.dist .env
# Edit .env and configure GOOGLE_CLOUD_ACCOUNT with your Google/Gmail account
```

> 💡 **Tip:** If `just workshop-test` reports that the billing API is disabled on your project, enable it quickly via:
> ```bash
> gcloud services enable cloudbilling.googleapis.com
> ```

### 2. ⏱️ Launch Terraform Infrastructure Asynchronously

Navigate to the `iac/` directory and initialize Terraform:
```bash
cd iac
terraform init
terraform apply -auto-approve
cd ..
```
*(Or use the top-level shorthand: `just terraform-apply`)*

**What Terraform Provisions:**
- **Google Cloud Storage Bucket:** Created with private access and IAM Credentials signing (`iam: true`).
- **Canary Test Image:** Uploads `gcs_dev_image.jpg` to the bucket to enable end-to-end blob verification.
- **Google Cloud SQL PostgreSQL Instance:** Initiates background provisioning (~10-12 minutes).

> 📸 **TODO(riccardo): add screenshot of Google Cloud SQL Console showing rails-postgres instance in state 'Creating' (cooking in background)**

### 3. Automated Step 1 Validation & Fast UAT

Verify that Step 1 prerequisites and configurations pass:
```bash
just workshop-eval 1
```

Want to see how an automated grader or clean CI runner evaluates this step in an isolated clone? Run our fast UAT harness:
```bash
just workshop-uat 1
```

✨ **The Wow Moment:** One command launches heavy enterprise infrastructure cooking in Google Cloud while you immediately proceed to local development without waiting!

## Step 2: The Local Baseline, Mailpit & Admin Onboarding

*Duration: 15min*

Our starting point is a clean, modern Rails 8 blog application running on localhost with SQLite, Mailpit email interception, and disk-based ActiveStorage.

### 1. Boot the App Locally

Start the local development stack:
```bash
bundle install
bin/rails db:setup
```

### 2. 🌱 Smart Seed Auto-Discovery & Admin Bootstrap (Issue #21 & #25)

The database seed (`db/seeds.rb`) features **Smart Environment Auto-Discovery**:
- It inspects your active database adapter (SQLite vs Postgres) and storage configuration.
- It detects **Stage 0 (Localhost)** and automatically creates the initial admin user and seeds the pedagogical post:
  - `[LOCAL BASELINE] Welcome to Rails 8 on Localhost!`
  - Out-of-the-box local sad image attachment (`local_sad_image.png`) with watermark informing you that local disk storage is ephemeral.
- It automatically triggers a password reset email via ActionMailer.

Run seed with your admin email:
```bash
GOOGLE_CLOUD_ACCOUNT="myname@gmail.com" bin/rails db:seed
```

Boot the services:
```bash
docker compose up
# (Or run bin/dev if running directly on your host machine)
```

### 3. The Mailpit Experience & Console Workout

1. **Catch Outgoing Emails**: Open `http://localhost:8025` in your browser. You will see **Mailpit** running locally. The initial seed or password reset dispatches an ActionMailer notification captured right here in the local inbox without touching real email servers!

> 📸 **TODO(riccardo): add screenshot of Mailpit web UI (http://localhost:8025) displaying the intercepted admin password reset email**

2. **Interactive `rails console`**: Test your Rails muscle memory by dropping into the console:
   ```bash
   bin/rails console
   ```
   Inspect your seeded admin user and practice resetting credentials in Ruby:
   ```ruby
   user = User.find_by(email_address: "myname@gmail.com")
   user.update!(password: "SuperSecret2026!")
   exit
   ```
3. **Log in to the Blog**: Open `http://localhost:3000` and log in with your updated admin credentials.
4. **Observe the Telemetry Badges:** Check the footer and UI header:
   - Notice the badge: `[EPHEMERAL DB / STORAGE] 💾 Local`
   - Notice the post watermark: The local casetta stamp (`nanobanana_stamp_local.png` in the bottom-right corner).

> 📸 **TODO(riccardo): add screenshot of the local blog homepage showing the yellow [EPHEMERAL DB / STORAGE] badge and the casetta stamp in the bottom-right of the cover image**

<!-- workshop-screenshot: id="step-2-home-ephemeral" -->
![Blog Homepage with Ephemeral DB Badge](assets/auto-screenshots/step-2-home-ephemeral.png)

### 4. Automated Step 2 Validation

Verify your local baseline and admin setup:
```bash
just workshop-eval 2
```

✨ **The Wow Moment:** Out-of-the-box rich-text editing, instant image drag-and-drop, email interception via Mailpit, and interactive Rails console mastery in under 5 minutes!

### 5. The Catch: Stateless Containers

Cloud Run containers are stateless and ephemeral. If we deploy our SQLite database and local `storage/` directory directly to Cloud Run, all posts and uploaded images will be permanently wiped out whenever a container scales to zero or restarts.

In the next step, we will intentionally deploy this ephemeral configuration to Cloud Run to witness the **Stateless Shock** first-hand!



## Step 3: Deploy 1 — The Stateless Shock (Early WOW in 3 Minutes!)

*Duration: 10min*

Instead of waiting 15–20 minutes for cloud databases before seeing anything on the web, modern serverless development begins with an early victory: deploying our single-container Rails application directly to **Google Cloud Run** in under 3 minutes!

### 1. The Time-Machine Rewind

To guarantee that our starting configuration is 100% ephemeral (local SQLite database and local disk file storage), use the Zero-Branch Time-Machine engine:

```bash
just workshop-rewind 1
```

> 💡 **What just happened?**  
> `workshop-rewind 1` applied the `stage-1-stateless` configuration overlay to `blog/config/` without leaving the `main` branch. Your app is configured with SQLite on container disk and ActiveStorage on local filesystem.

### 2. Deploying Single-Container Puma to Cloud Run

Deploy directly from source code to Cloud Run. Google Cloud automatically detects Rails 8, builds the container image with Google Cloud Buildpacks/Docker, and provisions a managed serverless service:

```bash
# Ensure default region is set
export GOOGLE_CLOUD_REGION="europe-west1"

# Deploy single-container service from source (with dummy key fallback if starting without credentials)
gcloud run deploy blog \
  --source . \
  --region $GOOGLE_CLOUD_REGION \
  --allow-unauthenticated \
  --set-env-vars GOOGLE_CLOUD_ACCOUNT=$GOOGLE_CLOUD_ACCOUNT,SECRET_KEY_BASE_DUMMY=1
```

During deployment:
1. Cloud Run builds your Rails container image.
2. It assigns a public, secure TLS domain: `https://blog-[hash]-[region].a.run.app`.
3. Traffic begins routing to Puma on port 8080.

### 3. ✨ The Early WOW Moment

Open the generated Cloud Run URL in your browser!

1. Your modern Rails 8 application is live on Google Cloud!
2. Log in with your admin credentials (`GOOGLE_CLOUD_ACCOUNT` and `APP_ADMIN_PASSWORD`).
3. Click **"New Post"**, write an article titled *"My First Cloud Run Post"*, attach a picture, and click **Create Post**.
4. Your post is published with full formatting, and your image is rendered.
5. Notice the visual telemetry:
   - Header badge: `[EPHEMERAL DB / STORAGE] 💾 Local`
   - Image watermark: The local casetta stamp (`127.0.0.1` ephemeral disk badge in the bottom-right corner).

> 🐝 **Join the Live Workshop Hive Leaderboard!**  
> Se sei online e il tuo proctor sta mostrando la leaderboard, e vuoi far parte della leaderboard, aggiungi il tuo Cloud Run URL qui:  
> 👉 [**Registra il tuo Cloud Run sulla Leaderboard**](https://docs.google.com/forms/d/e/1FAIpQLSf9iN_m8O5LVMeo7Z80OTo3t0IKv_UrOgEndZDmzdB5qwBa2A/viewform)

> 📸 **TODO(riccardo): add screenshot of Google Cloud Run Console showing the 'blog' service details and the live https://blog-xxx.a.run.app public URL**

### 4. 💥 The Catch: The Stateless Shock & The "Puma Workaround" Trap

Cloud Run is a **stateless, serverless platform**. When web traffic drops to zero, Cloud Run scales down to zero container instances to save money. When a new HTTP request arrives or a new container revision is deployed, Cloud Run starts a brand new, clean container image.

#### The First Hint: Stuck Jobs Banner
When you create a post or attach an image in a single-container deployment, Rails enqueues ActiveJob tasks (like image dimension analysis or metadata indexing). But since nobody is running a background worker, you will see the warning banner:
> ⚠️ **Notice: background jobs currently pending execution.**  
> *Solid Queue worker is not running in this single-container deployment.*

#### The Tempting Fix: Running Solid Queue inside Puma
A clever developer might say: *"Wait! In Rails 8, Puma has a plugin to run Solid Queue directly inside the web server process! Let's just turn on `SOLID_QUEUE_IN_PUMA=true`!"*

Let's test this workaround on Cloud Run:

```bash
# Force a revision update to enable Solid Queue inside Puma
gcloud run services update blog \
  --region $GOOGLE_CLOUD_REGION \
  --update-env-vars SOLID_QUEUE_IN_PUMA=true
```

Now, go back to your browser and **refresh the page**:

💥 **The Stateless Shock:**  
1. **The Good News:** The Solid Queue worker is now active inside Puma! Any new jobs get drained immediately.
2. **The Cold Shower (The Catch!):**  
   - Because Cloud Run deployed a new revision, the previous container instance was replaced!
   - The article you wrote and the SQLite database file on disk **were completely wiped out**!
   - You see the pedagogical in-app alert banner:
     > ⚠️ **`[EPHEMERAL CONTAINER RESET DETECTED]`**  
     > *"Container restarted! Ephemeral SQLite database and local disk uploads were lost. Ask Antigravity why serverless containers require external persistence!"*
3. **The Architectural Lesson:** Running background workers inside Puma consumes precious web thread CPU/RAM, and *still does not solve persistence*.

> 📸 **TODO(riccardo): add screenshot of the live Cloud Run blog showing the [EPHEMERAL CONTAINER RESET DETECTED] alert banner after container restart**

### 5. Automated Step 3 Validation

Verify your Cloud Run deployment and alert handling:

```bash
just workshop-eval 3
```

✨ **The Lesson:** Single-container workarounds like `SOLID_QUEUE_IN_PUMA` are handy for local development, but in modern cloud architecture:
- Media files require **Google Cloud Storage (GCS)** (Step 4).
- Relational data and job queues require managed **Google Cloud SQL** (Step 5).
- Heavy background workers belong in a dedicated **sidecar container** (Step 6).


## Step 4: Deploy 2 — GCS Persistent Storage & POLA Warning

*Duration: 15min*

In this step, we decouple media and file storage from the container disk by switching ActiveStorage to **Google Cloud Storage (GCS)**, using short-lived signed URLs via the IAM Credentials API (`iam: true`).

### 1. The Time-Machine Rewind

Advance the time machine to Stage 2:

```bash
just workshop-rewind 2
```

Inspect `blog/config/storage.yml`:

```yaml
google:
  service: GCS
  project: <%= ENV.fetch("GOOGLE_CLOUD_PROJECT") %>
  bucket: <%= ENV.fetch("GCS_BUCKET") %>
  iam: true  # Sign URLs via IAM Credentials signBlob API (zero private key JSON files required!)
```

> 💡 **Design Decision — Why `iam: true` instead of `public: true`?**  
> Making a bucket public (`allUsers:objectViewer`) is a hazardous security anti-pattern. With `iam: true`, your bucket remains **100% private**, and Rails generates secure, short-lived signed URLs on the fly via the IAM Credentials API.

![GCS IAM Signing Architecture](assets/images/gcs_iam_signing_diagram.jpg)

### 2. Granting IAM Storage & Signing Permissions

Ensure your Cloud Run runtime service account has permissions to sign URLs and upload objects:

```bash
export PROJECT_NUMBER=$(gcloud projects describe $GOOGLE_CLOUD_PROJECT --format="value(projectNumber)")
export RUN_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
export GCS_BUCKET="${GOOGLE_CLOUD_PROJECT}-activestorage-dev"

# Grant Storage Object Admin
gcloud storage buckets add-iam-policy-binding gs://$GCS_BUCKET \
  --member="serviceAccount:$RUN_SA" \
  --role="roles/storage.objectAdmin"

# Grant Service Account Token Creator (required for IAM signed URLs)
gcloud iam service-accounts add-iam-policy-binding $RUN_SA \
  --member="serviceAccount:$RUN_SA" \
  --role="roles/iam.serviceAccountTokenCreator"
```

### 3. Deploy 2 to Cloud Run with GCS Attached

Re-deploy our application with GCS enabled:

```bash
gcloud run deploy blog \
  --source . \
  --region $GOOGLE_CLOUD_REGION \
  --set-env-vars GOOGLE_CLOUD_ACCOUNT=$GOOGLE_CLOUD_ACCOUNT,GCS_BUCKET=$GCS_BUCKET,ACTIVE_STORAGE_SERVICE=google
```

### 4. ✨ The Surviving Image & The Cloud Stamp

1. Refresh your blog URL.
2. Create a new blog post titled *"Surviving the Cloud"* and upload a photo.
3. Look at the bottom-right corner of the image:
   - The casetta stamp is gone!
   - It is replaced by the colorful **Cloud GCS Stamp** (`nanobanana_stamp_cloud.png`).
4. Force another container restart:
   ```bash
   gcloud run services update blog --region $GOOGLE_CLOUD_REGION --update-env-vars RESTART_TRIGGER=$(date +%s)
   ```
5. Refresh the page: while the SQLite database reset, **the image binary is safe and sound in Google Cloud Storage**! Verify via CLI:
   ```bash
   gcloud storage ls gs://$GCS_BUCKET/
   ```

> 📸 **TODO(riccardo): add screenshot of Google Cloud Storage Console showing uploaded image blobs safely stored in the private bucket gs://$GCS_BUCKET**

### 5. ⚠️ The POLA Catch: Stuck Jobs Warning Banner

When you uploaded the image, ActiveStorage enqueued an analysis job (`ActiveStorage::AnalyzeJob`) to extract dimensions and metadata.

However, Cloud Run is currently running only **one single web container** (`puma`). In Rails 8, **Solid Queue** stores background jobs in the database, but nobody is executing `bundle exec rails solid_queue:start`!

Look at the top of your blog page: you will see a bright warning banner rendered by `blog/app/views/layouts/_check_stuck_jobs.html.erb`:

> ⚠️ **POLA Warning: Background Jobs Queued with No Worker!**  
> *"Pending jobs detected in Solid Queue, but no worker process is running. In a single-container deployment, background workers compete with or starve web requests. Ask Antigravity why background jobs require dedicated sidecar containers!"*

<!-- workshop-screenshot: id="step-4-gcs-stuck-jobs-warning" -->
![GCS ActiveStorage with Stuck Jobs Warning Banner](assets/auto-screenshots/step-4-gcs-stuck-jobs-warning.png)

### 6. Automated Step 4 Validation

Verify your GCS configuration and stuck jobs telemetry:

```bash
just workshop-eval 4
```


## Step 5: Cloud SQL Ready & Secret Manager CLI Injection

*Duration: 10min*

By now, the Cloud SQL PostgreSQL instance provisioned by Terraform in Step 1 has finished cooking in the background! In this step, we verify our database and inject our secrets into **Google Cloud Secret Manager**.

### 1. Verifying Cloud SQL Instance

Check the state of your Cloud SQL instance:

```bash
gcloud sql instances describe rails-postgres --format="value(state)"
```

The output should be `RUNNABLE`.

### 2. Google Cloud Secret Manager Injection

Never store plain-text database passwords, API keys, or Rails master keys in git or in container environment variables. We use **Google Cloud Secret Manager** for zero-trust runtime injection.

![Secret Manager Workflow](assets/images/secret_manager_workflow.jpg)

Store your secrets via the Google Cloud CLI:

```bash
# 1. Store Rails Master Key
gcloud secrets create rails-master-key --data-file=blog/config/master.key 2>/dev/null || \
  gcloud secrets versions add rails-master-key --data-file=blog/config/master.key

# 2. Store Cloud SQL Database Password (from Step 1 Terraform output)
export DB_PASSWORD=$(cd iac && terraform output -raw db_password 2>/dev/null || echo "RailsWorkshopSecure2026!")

echo -n "$DB_PASSWORD" | gcloud secrets create rails-db-password --data-file=- 2>/dev/null || \
  echo -n "$DB_PASSWORD" | gcloud secrets versions add rails-db-password --data-file=-
```

> 📸 **TODO(riccardo): add screenshot of Google Cloud Secret Manager Console listing rails-master-key and rails-db-password with Secret Accessor role bindings**

### 3. Granting Secret Accessor Permissions

Grant the Cloud Run runtime service account permission to read these secrets:

```bash
gcloud secrets add-iam-policy-binding rails-master-key \
  --member="serviceAccount:$RUN_SA" \
  --role="roles/secretmanager.secretAccessor"

gcloud secrets add-iam-policy-binding rails-db-password \
  --member="serviceAccount:$RUN_SA" \
  --role="roles/secretmanager.secretAccessor"
```

![Cloud SQL Auth Proxy Security Comparison](assets/images/cloud_sql_proxy_comparison.jpg)

### 4. Automated Step 5 Validation

Verify secret manager configuration:

```bash
just workshop-eval 5
```


## Step 6: Deploy 3 — Enterprise Multi-Container Sidecars (The Gold Standard)

*Duration: 20min*

Now we assemble the ultimate reference architecture: **Multi-Container Cloud Run**!

### 1. Restoring the Gold Standard

Restore your repository configuration to the canonical `main` state:

```bash
just workshop-restore-gold
```

### 2. Inspecting the 3-Container Production Blueprint

Open `blog/compose.prod.yaml` and inspect the architecture:

![Cloud Run Multi-Container Production Architecture](assets/images/cloud_run_multi_container_architecture.jpg)

```mermaid
graph LR
  Client[Internet / HTTPS Client] -->|Port 8080| Web[Web Container: Puma]
  Web -->|Localhost:5432| Proxy[Sidecar: Cloud SQL Auth Proxy]
  Worker[Worker Container: Solid Queue] -->|Localhost:5432| Proxy
  Proxy -->|IAM mTLS Tunnel| CloudSQL[(Google Cloud SQL PostgreSQL)]
```

The production deployment runs three coordinated containers sharing the same local network:
1. **`web`**: Serves HTTP traffic on port 8080 via Puma.
2. **`worker`**: Dedicated background processing container running `bundle exec rails solid_queue:start`.
3. **`cloudsql-proxy`**: Official Google Cloud SQL Auth Proxy sidecar (`gcr.io/cloud-sql-connectors/cloud-sql-proxy:2`) bound to `127.0.0.1:5432`.

### 3. Running Database Migrations via Cloud Run Job

Before routing web traffic, run migrations and database seeding against Cloud SQL using a transient Cloud Run Job:

```bash
# Create migration job
gcloud run jobs create rails-migrate \
  --source . \
  --command "bin/rails" \
  --args "db:migrate,db:seed" \
  --set-secrets="RAILS_MASTER_KEY=rails-master-key:latest,DB_PASSWORD=rails-db-password:latest" \
  --set-cloudsql-instances="${GOOGLE_CLOUD_PROJECT}:${GOOGLE_CLOUD_REGION}:rails-postgres" \
  --region $GOOGLE_CLOUD_REGION 2>/dev/null || true

# Execute migration job
gcloud run jobs execute rails-migrate --region $GOOGLE_CLOUD_REGION --wait
```

### 4. Deploy 3: Deploying Multi-Container Cloud Run

Deploy the full multi-container service:

```bash
gcloud run deploy blog \
  --source . \
  --region $GOOGLE_CLOUD_REGION \
  --allow-unauthenticated \
  --set-secrets="RAILS_MASTER_KEY=rails-master-key:latest,DB_PASSWORD=rails-db-password:latest" \
  --add-cloudsql-instances="${GOOGLE_CLOUD_PROJECT}:${GOOGLE_CLOUD_REGION}:rails-postgres" \
  --set-env-vars GOOGLE_CLOUD_ACCOUNT=$GOOGLE_CLOUD_ACCOUNT,GCS_BUCKET=$GCS_BUCKET,ACTIVE_STORAGE_SERVICE=google
```

> 📸 **TODO(riccardo): add screenshot of Google Cloud Run Console 'Containers' tab displaying the 3 sidecar containers (web, worker, cloudsql-proxy)**

### 5. ✨ The Wow Moment & Telemetry Validation

Open your Cloud Run URL:
1. Look at the telemetry badges:
   - **`[CLOUD PERSISTENT 🐘 ☁️]`** turns emerald green!
   - The stuck jobs warning banner is **gone**, because the `worker` container is actively draining Solid Queue in the background!
2. Create blog posts and comments.
3. Restart or redeploy as many times as you like: your data, posts, comments, and assets survive forever in Cloud SQL and GCS!

> 📸 **TODO(riccardo): add screenshot of the production blog showing the emerald green [CLOUD PERSISTENT 🐘 ☁️] badge with stuck jobs banner gone and permanent articles**

### 6. Automated Step 6 Validation

Verify the multi-container configuration:

```bash
just workshop-eval 6
```


## Step 7: Generative AI Pipelines, Podcastifier & The GCS Treasure Hunt 🏴‍☠️

*Duration: 15min*

![NanoBanana Mascot](assets/images/nano_banana_mascot.jpg)

With Solid Queue running in a dedicated container and Google Cloud Storage active, we can unleash asynchronous Generative AI!

### 1. The NanoBanana Vintage Cover Generator

![NanoBanana AI Image Generation Pipeline](assets/images/nanobanana_ai_image_pipeline.jpg)

When an article is created without a cover image, `GenerateCoverImageJob` automatically triggers via Solid Queue:
- It calls **Gemini 2.5 Flash Image / Imagen** on Vertex AI using **Application Default Credentials** (`roles/aiplatform.user`). Zero API keys required!
- It generates a custom vintage 1960s Italian film poster (*"Locandina di un film 1960"*) with a cameo banana and a shiny ruby "8".
- Test it: Create an article titled *"Serverless Architecture with Ruby on Rails"* and leave the cover image blank. Within seconds, the Solid Queue worker generates and attaches the poster!

> 📸 **TODO(riccardo): add screenshot of a blog post with an AI-generated vintage 1960s Italian movie poster featuring a cameo banana and ruby 8**

### 2. The Bilingual Podcastifier Quest (TTS Synthesis Exercise)

In this hands-on workshop exercise, you pair program with **Google Antigravity** to implement audio podcasts for your articles:
- Ask Antigravity: *"Help me implement a PodcastifierJob that uses Google Cloud Text-to-Speech with voice 'it-IT-Wavenet-A' to generate an Italian audio overview and attach it via ActiveStorage!"*
- Ensure your synthesizer specifies the canonical Italian voice: `voice: "it-IT-Wavenet-A"` and language code: `it-IT` using Application Default Credentials.
- Add a **"🎙️ Generate Audio Podcast"** button to the post view and render an HTML5 `<audio controls>` player when attached.
- When you click generate, Solid Queue executes the synthesis in the background without blocking web requests!

> 💡 **Reference Implementation Branch:**  
> If you get stuck or want to inspect a complete reference solution, check out the dedicated branch:  
> [`solutions/podcastifier`](https://github.com/palladius/rails8-app-on-gcp/tree/solutions/podcastifier) (`git checkout solutions/podcastifier`).

### 3. 🏴‍☠️ The GCS Treasure Hunt (Console Blob Recovery)

Remember that photo you uploaded back in Step 4 before the container restart wiped out the ephemeral SQLite database? That image file is still sitting safely in your private GCS bucket as an "orphaned blob"!

Let's use the Rails console to rescue it and attach it to a Cloud SQL post:

```bash
# Connect to your production database via Rails console and Cloud SQL Proxy
cloud-sql-proxy --port 5432 ${GOOGLE_CLOUD_PROJECT}:${GOOGLE_CLOUD_REGION}:rails-postgres &
DATABASE_URL=postgresql://rails_user:${DB_PASSWORD}@127.0.0.1:5432/rails_production bin/rails c
```

Inside the Rails console:

```ruby
# 1. Search for orphaned GCS blobs in ActiveStorage
orphan_blobs = ActiveStorage::Blob.where.missing(:attachments)
puts "🏴‍☠️ Found #{orphan_blobs.count} orphaned GCS blobs!"

# 2. Attach the surviving blob to your latest post
if orphan_blobs.any?
  post = Post.last
  post.cover_image.attach(orphan_blobs.first)
  post.save!
  puts "🎉 Rescued blob #{orphan_blobs.first.filename} attached to '#{post.title}'!"
end
exit
```

> 📸 **TODO(riccardo): add screenshot of the interactive Rails console executing the GCS Treasure Hunt snippet and rescuing orphaned ActiveStorage blobs**

Refresh your blog: the photo uploaded during Step 4's Stateless Shock is resurrected and permanently attached to your Cloud SQL post!

### 4. Automated Step 7 Validation

Verify GenAI jobs and assets:

```bash
just workshop-eval 7
```


## Step 8: Choose Your Own Adventure / Advanced Quests 🏆

*Duration: 30min*

Now that you have mastered the canonical reference architecture, choose your graduation quest!

---

### 🛡️ Quest 1: Zero-Trust Google IAP (Identity-Aware Proxy)
* **Difficulty:** Medium (Enterprise Security)
* **The Goal:** Lock down your Cloud Run application so only your verified Google / Gmail accounts can access it, eliminating password login entirely!
* **How it Works:**
  1. An External HTTPS Application Load Balancer terminates Google OAuth and verifies identity before traffic ever reaches Cloud Run.
  2. Google forwards verified identity headers (`X-Goog-Authenticated-User-Email`).
  3. Rails automatically logs in the verified Google identity via `blog/app/controllers/concerns/iap_authenticatable.rb`:
     ```ruby
     module IapAuthenticatable
       extend ActiveSupport::Concern
       included { before_action :authenticate_via_iap }

       private
       def authenticate_via_iap
         return unless (raw = request.headers["X-Goog-Authenticated-User-Email"]).present?
         email = raw.sub(/^accounts\.google\.com:/, "")
         user = User.find_or_create_by!(email_address: email) { |u| u.password = SecureRandom.hex(16) }
         start_new_session_for(user) unless authenticated?
       end
     end
     ```
  4. Enable the Terraform module in `iac/iap.tf` with `enable_iap = true` and specify your allowed Google accounts:
     ```hcl
     iap_allowed_users = [var.google_cloud_account]
     ```

> 📸 **TODO(riccardo): add screenshot of Google Cloud Identity-Aware Proxy (IAP) toggle and OAuth access screen**

---

### 📊 Quest 2: Production SRE Telemetry & Cloud Logging
* **Difficulty:** Medium (Observability)
* **The Goal:** Stream structured JSON application logs with trace correlation IDs directly to Google Cloud Logging and catch production exceptions in real-time with Cloud Error Reporting.
* **How it Works:**
  - Configure `blog/config/environments/production.rb` to emit structured JSON logs with GCP trace labels.
  - Trigger an intentional test exception and watch Google Cloud Error Reporting group and notify you instantly.

> 📸 **TODO(riccardo): add screenshot of Google Cloud Error Reporting showing grouped production exceptions and Cloud Logging structured JSON payload with trace labels**

---

### 🧠 Quest 3: `pgvector` Semantic Search & Gemini RAG
* **Difficulty:** Hard (GenAI Capstone)
* **The Goal:** Search articles conceptually using vector embeddings stored in PostgreSQL on Cloud SQL.
* **How it Works:**
  - Enable the `vector` extension on your Cloud SQL PostgreSQL instance:
    ```sql
    CREATE EXTENSION IF NOT EXISTS vector;
    ```
  - Add the `neighbor` gem to `blog/Gemfile` and generate text embeddings with Gemini (`text-embedding-004`) on `Post#after_save`.
  - Perform cosine distance queries (`<=>`) to power a semantic search bar with Turbo Streams!

> 📸 **TODO(riccardo): add screenshot of the live blog semantic search bar returning conceptual matches with cosine similarity scores**

---

### ⚡ Quest 4: SEO & Performance Audit Assistant
* **Difficulty:** Easy / Fun (Developer Experience)
* **The Goal:** Audit Core Web Vitals, Largest Contentful Paint (LCP), and Flesch-Kincaid / Fog readability indices using Antigravity and Speedgrapher tools.

> 📸 **TODO(riccardo): add screenshot of Speedgrapher / Lighthouse SEO and Core Web Vitals audit summary**

---

## 🎓 Conclusion & Clean Up

*Duration: 5min*

Congratulations! 🎉

You have built and deployed a production-grade, enterprise-ready Rails 8 application on Google Cloud Platform:
- **Zero-Branch Progression:** Mastered modern workflows with Time-Machine overlays on `main`.
- **Cloud Storage:** Scalable, private object storage with IAM blob signing (`iam: true`).
- **Cloud SQL:** Managed PostgreSQL secured with Cloud SQL Auth Proxy mTLS tunnels.
- **Secret Manager:** Zero plain-text credentials or `.env` file leaks.
- **Cloud Run Multi-Container:** Isolated Puma web, Solid Queue worker, and proxy sidecars.
- **Generative AI:** Asynchronous vintage poster generation and TTS podcast synthesis with Vertex AI.
- **Quests:** Zero-Trust IAP, SRE Observability, and pgvector embeddings!

### 🧹 Resource Clean Up

To avoid ongoing charges after completing the workshop, make sure to clean up your Google Cloud resources! Choose the approach that best fits your environment:

#### Option 1: Terraform Teardown (Recommended / Default 🟢)
> Use this option if you are using an existing or shared Google Cloud project where other resources or data live. It surgically destroys **only** the resources provisioned during this workshop (Cloud Run, Cloud SQL, Secret Manager, GCS buckets), leaving the rest of your project untouched.

```bash
cd iac
terraform destroy -auto-approve
```

#### Option 2: Total Project Deletion (Leave Zero Trace 🌪️)
> Use this option if you created a dedicated workshop project (e.g., using workshop credits or a sandbox) and want to guarantee that **zero trace** remains—including logs, metadata, service accounts, and billing links.

```bash
gcloud projects delete $GOOGLE_CLOUD_PROJECT --quiet
```


