<!-- ⚠️ AGENT WARNING: This file (CODELAB.md) and SKELETON.md must be kept in sync at all times. A change to one requires a change to the other! -->
<!-- 📜 Adheres to docs/CONSTITUTION.md (v1.1.0) -->
<!-- 🏷️ Codelab Version: 2.0.0alpha -->
# Rails 8 on Google Cloud: From Zero to AI

## Introduction

![Rails on Google Cloud](assets/images/rails_gcp_logo.jpg)

Welcome to the **Rails 8 on Google Cloud** workshop (v2.0.0alpha)! In this hands-on codelab, you will take a modern Rails 8 application from a simple local SQLite baseline to a production-grade, enterprise-ready reference architecture on Google Cloud.

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

Let's get started!

## Step 0: Prerequisites, Antigravity Setup & Billing Verification

> 💡 **The Scenario:** You and your team are building a mission-critical Rails 8 application. Before touching code or launching cloud resources, we must establish our toolchain, connect Google Antigravity, and verify our Google Cloud credentials and billing foundation.

### 1. Prerequisites Checklist

Before we begin, ensure you have the following tools available in your environment:
- **Google Cloud SDK (`gcloud` CLI):** Installed and up to date.
- **Terraform CLI (1.5+):** For declarative infrastructure provisioning.
- **Docker & Docker Compose:** Installed and running locally.
- **Ruby 3.3+ & Rails 8:** (`ruby -v`, `rails -v`).
- **Google Antigravity IDE / Gemini CLI:** Your autonomous AI pair programming assistant ([Download Google Antigravity](https://antigravity.google/download)).

### 2. Google Cloud Authentication & Project Selection

Authenticate your user account and Application Default Credentials (ADC), which allows Google Antigravity, Vertex AI, and local test suites to communicate securely with Google Cloud:

```bash
gcloud auth login
gcloud auth application-default login
```

Set your active Google Cloud Project ID:
```bash
export PROJECT_ID="your-project-id"
gcloud config set project $PROJECT_ID
```

### 3. 🚨 Mandatory Guard Gate: GCP Billing Verification

> ⚠️ **CRITICAL GUARD GATE:** Google Cloud SQL and Cloud Run deployments require an active linked billing account or valid workshop educational credits. Checking this now prevents cryptic quota or billing failures halfway through the lab!

Run the billing verification check:
```bash
gcloud beta billing projects describe $PROJECT_ID
```
Ensure `billingEnabled: true` is returned. If billing is disabled, link a billing account or redeem your workshop credit coupon in the [Google Cloud Console Billing Page](https://console.cloud.google.com/billing).

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

> 💡 **The Strategy:** Managed databases like Google Cloud SQL PostgreSQL take approximately 10–12 minutes to provision. Rather than waiting idly later, we launch immutable infrastructure via Terraform **right now in the background** while we develop locally!

### 1. Run Automated Pre-Flight Diagnostics Suite

Before launching cloud infrastructure, run the comprehensive pre-flight test suite:
```bash
just workshop-test
```
This script (`bin/workshop_diagnostics.rb`):
- Verifies your `ADMIN_EMAIL` identity configuration.
- Verifies active billing and project linkage.
- Validates Application Default Credentials (ADC) for Vertex AI.
- Confirms the ActiveStorage canary seed image (`blog/app/assets/images/gcs_dev_image.jpg`).

If `.env` is missing, copy it from the documented template:
```bash
cp .env.dist .env
# Edit .env and configure ADMIN_EMAIL with your Google/Gmail account
```

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
ADMIN_EMAIL="myname@gmail.com" bin/rails db:seed
```

Boot the services:
```bash
docker compose up
# (Or run bin/dev if running directly on your host machine)
```

### 3. The Mailpit Experience & Console Workout

1. **Catch Outgoing Emails**: Open `http://localhost:8025` in your browser. You will see **Mailpit** running locally. The initial seed or password reset dispatches an ActionMailer notification captured right here in the local inbox without touching real email servers!
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
   - Notice the post watermark: *"Stored on ephemeral local disk: sad grayscale mode 💾 (ask AI why!)"*.

### 4. Automated Step 2 Validation

Verify your local baseline and admin setup:
```bash
just workshop-eval 2
```

✨ **The Wow Moment:** Out-of-the-box rich-text editing, instant image drag-and-drop, email interception via Mailpit, and interactive Rails console mastery in under 5 minutes!

### 5. The Catch: Stateless Containers

Cloud Run containers are stateless and ephemeral. If we deploy our SQLite database and local `storage/` directory directly to Cloud Run, all posts and uploaded images will be permanently wiped out whenever a container scales to zero or restarts.

In the next step, we will intentionally deploy this ephemeral configuration to Cloud Run to witness the **Stateless Shock** first-hand!


## Step 2: Cloud Storage

Currently, uploaded images are saved locally in the `storage/` folder. We will migrate ActiveStorage to Google Cloud Storage (GCS) using short-lived signed URLs.

1. Checkout the next branch:
   ```bash
   git checkout workshop_2_cloud_storage
   ```

2. Open `config/storage.yml` and inspect the `google` service definition:
   ```yaml
   google:
     service: GCS
     project: <%= ENV.fetch("GOOGLE_CLOUD_PROJECT") %>
     bucket: <%= ENV.fetch("GCS_BUCKET_NAME") %>
     iam: true  # Sign URLs via IAM Credentials signBlob API (no private key JSON required!)
   ```

3. Open `config/environments/production.rb` (and `development.rb` if testing remote storage locally) and set:
   ```ruby
   config.active_storage.service = :google
   ```

> 💡 **Design Decision — Why `iam: true` instead of `public: true`?**  
> Making a bucket public (`public: true` / `allUsers:objectViewer`) exposes every uploaded file to the entire internet forever. With `iam: true`, your bucket remains **100% private**, and Rails generates secure, short-lived signed URLs on the fly via the IAM Credentials API.

✨ **The Wow Moment:** Create or edit a post and drag-and-drop an image into the editor. Open your browser developer tools (Network tab) and Google Cloud Storage Console. You can see the image binary stream directly into your private GCS bucket, served back via an expiring secure signed URL!

## Step 3: Cloud SQL (From Naive Exposure to Auth Proxy)

Check your terminal: by now, your Cloud SQL PostgreSQL instance has finished provisioning!

Let's switch our application from SQLite to Cloud SQL.

1. Checkout the next branch:
   ```bash
   git checkout workshop_3_cloud_sql
   ```

### Phase 3A: The Naive Connection (The `0.0.0.0/0` Anti-Pattern)

To demonstrate how traditional setups connected to databases, let's create a database user and open the firewall:

1. Create the database and user:
   ```bash
   gcloud sql databases create rails_production --instance=$CLOUDSQL_INSTANCE_NAME
   gcloud sql users create rails_user --instance=$CLOUDSQL_INSTANCE_NAME --password=$DB_PASSWORD
   ```

2. Add an authorized network rule for `0.0.0.0/0`:
   ```bash
   gcloud sql instances patch $CLOUDSQL_INSTANCE_NAME --authorized-networks=0.0.0.0/0
   ```

3. Test direct public connection:
   ```bash
   psql -h $CLOUDSQL_PUBLIC_IP -U rails_user -d rails_production
   ```

> ⚠️ **CAUTION: The Security Anti-Pattern.**  
> Exposing port `5432` to `0.0.0.0/0` on the public internet exposes your database to brute-force attacks, port scanning bots, and catastrophic leaks. We did this only to prove connectivity—now we immediately lock it down!

### Phase 3B: The Secure Solution — Cloud SQL Auth Proxy

Let's remove the public network authorization and connect through the secure **Cloud SQL Auth Proxy**:

1. Remove `0.0.0.0/0` from authorized networks:
   ```bash
   gcloud sql instances patch $CLOUDSQL_INSTANCE_NAME --clear-authorized-networks
   ```

2. Start the Cloud SQL Auth Proxy locally on port 5432:
   ```bash
   cloud-sql-proxy --port 5432 $CLOUDSQL_INSTANCE_CONNECTION_NAME
   ```

3. In another terminal, run your database migrations and seed through the secure local proxy:
   ```bash
   DATABASE_URL=postgresql://rails_user:${DB_PASSWORD}@127.0.0.1:5432/rails_production bin/rails db:migrate db:seed
   ```

4. Start your Rails server:
   ```bash
   DATABASE_URL=postgresql://rails_user:${DB_PASSWORD}@127.0.0.1:5432/rails_production bin/rails s
   ```

✨ **The Wow Moment:** Refresh `http://localhost:3000`! You will see a newly seeded welcome article: *"🐘 Welcome to Cloud SQL!"* loaded live from your managed PostgreSQL instance in the cloud via the secure IAM proxy tunnel without any open public firewall ports!

## Step 4: Secret Manager

Never store plain-text passwords or secret keys in source control or `.env` files. We use **Google Cloud Secret Manager** to securely manage credentials.

1. Checkout the next branch:
   ```bash
   git checkout workshop_4_secret_manager
   ```

2. Store your Rails master key and database password in Secret Manager:
   ```bash
   gcloud secrets create rails-master-key --data-file=config/master.key
   gcloud secrets create rails-db-password --data-file=<(echo -n "$DB_PASSWORD")
   ```

3. Verify secret storage and retrieval directly from the CLI:
   ```bash
   gcloud secrets versions access latest --secret=rails-master-key
   ```

4. Grant your Cloud Run service account permission to access the secrets:
   ```bash
   gcloud secrets add-iam-policy-binding rails-master-key \
     --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
     --role="roles/secretmanager.secretAccessor"

   gcloud secrets add-iam-policy-binding rails-db-password \
     --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
     --role="roles/secretmanager.secretAccessor"
   ```

✨ **The Wow Moment:** You can safely delete local `.env` and credential files; Cloud Run will automatically fetch and inject these secrets into your container environment at runtime.

## Step 5: Multi-Container Cloud Run & Docker Compose

In modern Rails 8 applications, background jobs are processed by **Solid Queue**. In production, we separate web traffic from background workers and attach the Cloud SQL Proxy as a sidecar container.

1. Checkout the next branch:
   ```bash
   git checkout workshop_5_cloud_run_classic
   ```

2. Inspect `compose.prod.yaml`:
   - **`web`**: Serves HTTP requests on port 8080.
   - **`worker`**: Runs Solid Queue (`bundle exec rails solid_queue:start`).
   - **`cloudsql-proxy`**: Official proxy sidecar container (`gcr.io/cloud-sql-connectors/cloud-sql-proxy:2`) bound to `5432`.

3. Test the multi-container stack locally:
   ```bash
   docker compose -f compose.prod.yaml up
   ```

4. Deploy the multi-container service to Cloud Run:
   ```bash
   gcloud run deploy rails-blog \
     --source . \
     --region us-central1 \
     --allow-unauthenticated \
     --set-secrets="RAILS_MASTER_KEY=rails-master-key:latest,DB_PASSWORD=rails-db-password:latest"
   ```

✨ **The Wow Moment:** The entire 3-container production stack (Web + Background Worker + Cloud SQL Proxy sidecar) boots locally with one Docker Compose command and deploys live to Cloud Run with zero architectural drift!

## Step 6: Automating with Cloud Build (Optional / Skippable)

> 💡 **Note:** If you want to jump straight to building AI features, you can skip this step and proceed to Step 7!

Manual deployments from a developer laptop are error-prone. Let's automate the deployment with **Cloud Build**.

1. Checkout the next branch:
   ```bash
   git checkout workshop_6_cloud_build_cicd
   ```

2. Inspect `cloudbuild.yaml`. It defines 3 automated pipeline steps:
   - **Build**: Compiles the production Docker image.
   - **Migrate**: Runs `rails db:migrate` using a transient Cloud Run Job.
   - **Deploy**: Updates the Cloud Run service with the newly built container image.

3. Connect your GitHub repository to Cloud Build using the GCP Console Triggers page.

✨ **The Wow Moment:** Every `git push` to `main` triggers a fully automated build, test, migration, and deployment in Google Cloud!

## Step 7: AI Features and Background Jobs

![NanoBanana Mascot](assets/images/nano_banana_mascot.jpg)

Rails 8's **Solid Queue** powers asynchronous background tasks without needing Redis. Let's use it for an AI feature: **The "NanoBanana" Auto-Cover Generator**.

1. Checkout our final branch:
   ```bash
   git checkout workshop_7_ai_features
   ```

2. When a post is saved without a cover image, `GenerateCoverImageJob` triggers (the logic lives in `blog/lib/nanobanana.rb`):
   - It sends the post title and body to **Nano Banana** (`gemini-2.5-flash-image`) on **Vertex AI** with this prompt:
     > *"The poster is the cover image for a blog post titled [Title]. The article contains the following text: [Text]. CRITICAL STYLE INSTRUCTION: The image MUST be rendered in the style of a 'Locandina di un film 1960' (a vintage 1960s Italian movie poster). Maintain a beautiful, cohesive vintage Italian cinematic aesthetic. You MUST feature a banana somewhere in the scene. You MUST place a shiny red ruby gem shaped like the digit "8" in the top-right corner of the image."*
   - Too lazy to write a real title? Anything under 30 bytes or keyboard mash like `qwerty` gets a poster of an epic **Prog Metal concert in Modena** instead.
   - Authentication is **Application Default Credentials only**: on Cloud Run the service account (Terraform grants `roles/aiplatform.user` and enables `aiplatform.googleapis.com`), on your laptop `gcloud auth application-default login`. No `GEMINI_API_KEY` anywhere.
   - The Solid Queue worker decodes the returned image, **stamps its provenance** — grayscale with a little house and `127.0.0.1` when it is stored on the ephemeral local disk, a colorful cloud when it is stored on GCS — and attaches it via ActiveStorage.
   - No credentials, no API, no network? The job attaches a bundled *"NO VERTEX AI CREDENTIALS — I'm a fake cover image, pretend I'm real"* poster. Nothing crashes, ever.

3. Create a new post, leave the cover image empty, and publish.

✨ **The Wow Moment:** In a few seconds, an AI-generated vintage Italian poster featuring a cameo banana and a ruby "8" appears automatically on your post, processed completely asynchronously by Solid Queue on Cloud Run — and the stamp in the corner tells you whether your storage is still ephemeral or already in the cloud! Covers you upload yourself follow the same rule: sad grayscale while on local disk, full color once on GCS.

## Step 8: Choose Your Own Adventure (The Quests 🏆)

Now that you have deployed the canonical reference architecture to Cloud Run, the rest of the journey is open-ended! Choose one of the quests below based on your appetite:

---

### 🛡️ Quest 1: Zero-Trust Google IAP (Identity-Aware Proxy)
* **Difficulty:** Medium (Enterprise Security)
* **The Goal:** Lock down your Cloud Run application so only your verified Google / Gmail accounts can access it, eliminating password login entirely!
* **How it Works:**
  1. An External HTTPS Application Load Balancer terminates Google OAuth and verifies identity before traffic ever reaches Cloud Run.
  2. Google forwards verified identity headers (`X-Goog-Authenticated-User-Email`).
  3. Rails automatically logs in the verified Google identity via a controller concern:
     ```ruby
     # app/controllers/concerns/iap_authenticatable.rb
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
     iap_allowed_users = ["myemail@gmail.com", "teacher@gmail.com"]
     ```

---

### 📊 Quest 2: Production SRE Telemetry & Cloud Logging
* **Difficulty:** Medium (Observability)
* **The Goal:** Stream structured JSON application logs with trace correlation IDs directly to Google Cloud Logging and catch production exceptions in real-time with Cloud Error Reporting.
* **How it Works:**
  - Configure `config/environments/production.rb` to emit structured JSON logs.
  - Trigger an intentional test exception and watch Google Cloud Error Reporting group and notify you instantly.

---

### 🧠 Quest 3: `pgvector` Semantic Search & Gemini RAG Boss Level
* **Difficulty:** Hard (GenAI Capstone)
* **The Goal:** Search articles conceptually using vector embeddings stored in PostgreSQL on Cloud SQL.
* **How it Works:**
  - Run `CREATE EXTENSION vector;` on your Cloud SQL PostgreSQL instance.
  - Add the `neighbor` gem and generate text embeddings with Gemini (`text-embedding-004`) on `Post#after_save`.
  - Perform cosine distance queries (`<=>`) to power a semantic search bar with Turbo Streams!

---

## Conclusion

Congratulations! 🎉

You have built and deployed a production-grade, enterprise-ready Rails 8 application on Google Cloud:
- **Cloud Storage:** Scalable, private object storage with IAM blob signing.
- **Cloud SQL:** Managed PostgreSQL secured with Cloud SQL Auth Proxy.
- **Secret Manager:** Zero plain-text credentials or `.env` file leaks.
- **Cloud Run Multi-Container:** Isolated Puma web and Solid Queue worker containers with a proxy sidecar.
- **Cloud Build:** Zero-touch automated CI/CD.
- **Generative AI:** Contextual vintage poster generation with Gemini and Solid Queue.
- **Quests:** Zero-Trust IAP, SRE Observability, and pgvector embeddings!

