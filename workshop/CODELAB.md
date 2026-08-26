<!-- ⚠️ AGENT WARNING: This file (CODELAB.md) and SKELETON.md must be kept in sync at all times. A change to one requires a change to the other! -->
<!-- 📜 Adheres to workshop/UNTOUCHABLE-CONSTITUTION.md -->
# Rails 8 on Google Cloud: From Zero to AI

## Introduction

![Rails on Google Cloud](assets/images/rails_gcp_logo.jpg)

Welcome to the Rails 8 on Google Cloud workshop! In this hands-on codelab, you will take a modern Rails 8 application from a simple local SQLite setup to a fully scalable, secure, and AI-powered production application on Google Cloud.

We will explore best practices for deploying Rails 8, managing secrets, connecting securely to Cloud SQL via the **Cloud SQL Auth Proxy**, orchestrating multi-container services on Cloud Run with Docker Compose, and tapping into Google's Gemini models for generative AI features.

### What you'll learn
- How to provision Google Cloud infrastructure asynchronously using Terraform or CLI scripts.
- How to transition from local disk storage to private Google Cloud Storage with IAM blob signing.
- How to connect Rails to Cloud SQL using the Cloud SQL Auth Proxy (and why opening to `0.0.0.0/0` is an anti-pattern).
- How to manage secrets securely using Google Cloud Secret Manager.
- How to run multi-container setups (`web` + Solid Queue `worker` + `cloudsql-proxy` sidecar) in Docker Compose and deploy them to Cloud Run.
- How to build AI-powered background features (like the **NanoBanana Auto-Cover Generator**) using Solid Queue and Gemini.

Let's get started!

## Setup and Prerequisites

> 💡 **The Scenario:** Your team needs to modernize a Rails application for production on Google Cloud. The app was built locally with SQLite and local image storage, but it has high business value. We want a clean, zero-magic, production-grade cloud architecture with proper database pooling, private object storage, secret management, and AI background processing.

### Prerequisites

Before we begin, make sure you have:

1. **A Google Cloud Project:**
   - **Full Track:** With billing enabled (for Cloud SQL and Cloud Storage).
   - **Zero-Billing Track:** A Free Tier project using Gemini Free API Key (*ohne* Cloud SQL).
2. **Google Cloud CLI:** Installed and authenticated:
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```
   Verify your active project:
   ```bash
   gcloud config get-value project
   ```
3. **Ruby & Rails:** Ruby 3.3+ and Rails 8 installed (`gem install rails`).
4. **Terraform & Docker:** Installed and available on your PATH.
5. **Cloud SQL Auth Proxy:** Download the binary from [Google Cloud](https://cloud.google.com/sql/docs/postgres/connect-auth-proxy#install) or install via package manager.
6. **AI Pair Programming (Google Antigravity):**
   - **Standalone IDE:** Install [Google Antigravity](https://antigravity.google/download).
   - **VS Code Extension:** Run `code --install-extension Google.google-antigravity`.

### Clone the Repository

```bash
git clone https://github.com/palladius/rails8-app-on-gcp.git
cd rails8-app-on-gcp
git checkout workshop_1_local_baseline
```

### ⏱️ Launch Cloud SQL Provisioning Immediately!

Cloud SQL instances take about 10–12 minutes to provision. Rather than waiting later, we kick off provisioning right now in the background:

```bash
./bin/provision-cloudsql.sh
```
*(Or navigate to `iac/` and run `terraform init && terraform apply -auto-approve`)*

✨ **The Wow Moment:** One command starts heavy cloud provisioning asynchronously in the background. While Google Cloud builds your managed database, let's jump straight into our local Rails 8 application!

## Step 1: The Local Baseline

Our starting point is a clean Rails 8 blog application running on SQLite with disk-based ActiveStorage.

### 1. Boot the App Locally

Run the setup commands to get the app running:

```bash
bundle install
bin/rails db:setup
bin/dev
```

Open `http://localhost:3000` in your browser. You can log in with the seeded credentials:
- **Email:** `riccardo@example.com`
- **Password:** `Ch4ng3m3!!1`

✨ **The Wow Moment:** The application is fully working locally in under 2 minutes! Try creating a new blog post and drag-and-drop an image directly into the ActionText / Trix rich-text editor. It uploads and renders instantly from your local disk storage.

### 2. Antigravity & Gemini Code Exploration

Let's use Antigravity / Gemini to inspect our application structure:
> *"Ask Gemini in Antigravity: Analyze our ActiveRecord models and generate a Mermaid diagram illustrating our Post, User, and ActiveStorage relationships."*

### 3. The Catch: Stateless Containers

Cloud Run containers are stateless and ephemeral. If we deploy our SQLite database and local `storage/` directory directly to Cloud Run, all posts and uploaded images will be permanently wiped out whenever a container scales to zero or restarts.

We need cloud-native persistence: **Cloud Storage** for assets, and **Cloud SQL** for our relational data.

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
     project: <%= ENV.fetch("GCP_PROJECT_ID") %>
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

2. When a post is saved without a cover image, `GenerateCoverImageJob` triggers:
   - It sends the post title and summary to Google's Gemini / Imagen model with this prompt:
     > *"Create a cover image for a blog post titled [Title]. The article contains the following text: [Text]. CRITICAL STYLE INSTRUCTION: The image MUST be rendered in the style of a 'Locandina di un film 1960' (a vintage 1960s Italian movie poster). Maintain a beautiful vintage Italian cinematic aesthetic. Also, you MUST feature a banana somewhere in the scene."*
   - The Solid Queue worker downloads the generated image and attaches it directly via ActiveStorage.

3. Create a new post, leave the cover image empty, and publish.

✨ **The Wow Moment:** In a few seconds, an AI-generated vintage Italian poster featuring a cameo banana appears automatically on your post, processed completely asynchronously by Solid Queue on Cloud Run!

## Conclusion

Congratulations! 🎉

You have taken a local Rails 8 application and transformed it into a cloud-native architecture on Google Cloud:
- **Cloud Storage:** Scalable, private object storage with IAM blob signing.
- **Cloud SQL:** Managed PostgreSQL secured with Cloud SQL Auth Proxy.
- **Secret Manager:** Zero plain-text credentials or `.env` file leaks.
- **Cloud Run Multi-Container:** Isolated Puma web and Solid Queue worker containers with a proxy sidecar.
- **Cloud Build:** Zero-touch automated CI/CD (optional).
- **Generative AI:** Contextual vintage poster generation with Gemini and Solid Queue.

### Extra Credit & Next Steps
- Explore `IDEAS.md` for Kamal deployments on GCE.
- Check out the **Podcastifier** for multi-language text-to-speech audio articles.
