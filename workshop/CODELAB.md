# Rails 8 on Google Cloud: From Zero to AI

## Introduction

Welcome to the Rails 8 on Google Cloud workshop! In this hands-on codelab, you will take a modern Rails 8 application from a simple local SQLite setup to a fully scalable, secure, and AI-powered production application on Google Cloud. 

We will explore the best practices for deploying Rails, managing secrets, utilizing Cloud SQL, and tapping into Google's Gemini models for generative AI features.

### What you'll learn
- How to provision Google Cloud infrastructure using Terraform.
- How to transition from local disk storage to Google Cloud Storage (ActiveStorage).
- How to securely connect Rails to Cloud SQL (PostgreSQL).
- How to use Secret Manager to keep your credentials safe.
- How to deploy your application to Cloud Run.
- How to automate your deployments with Cloud Build.
- How to build AI-powered features (like an auto-generating cover image) using Solid Queue and Gemini.

Let's get started!

## Setup and Prerequisites

Before we begin, you will need a few things set up:

1. **A Google Cloud Project:** Ensure you have a GCP project created and billing enabled.
2. **Google Cloud CLI:** The `gcloud` CLI should be installed and authenticated (`gcloud auth login`).
3. **Ruby and Rails:** You should have Ruby 3.3+ and Rails 8 installed locally.
4. **Terraform:** We will use Terraform to provision the heavy infrastructure.

First, clone the workshop repository and move into the `workshop_1_local_baseline` branch:

```bash
git clone https://github.com/palladius/rails8-app-on-gcp.git
cd rails8-app-on-gcp
git checkout workshop_1_local_baseline
```

## Step 1: The Local Baseline

Our starting point is a standard Rails 8 blog application. It uses SQLite for the database and stores images on your local hard drive. 

Run the setup commands to get the app running locally:

```bash
bundle install
bin/rails db:setup
bin/dev
```

Open `http://localhost:3000` in your browser. You should see a basic blog. Try creating a post and uploading an image. It works perfectly on your machine!

**The Catch:** Cloud Run containers are stateless. If we deploy this right now, your SQLite database and local images will be wiped out every time the container restarts. We need to move our state to the cloud.

### Provisioning the Cloud Infrastructure

Cloud SQL takes about 15 minutes to provision. Let's start that process now so it's ready when we need it!

Open a new terminal tab and run:

```bash
cd iac/
terraform init
terraform apply -auto-approve
```

While Terraform does the heavy lifting in the background, let's fix our storage!

## Step 2: Cloud Storage

Currently, our blog images are stored in the `storage/` directory locally. We need to move this to Google Cloud Storage (GCS) so our images survive container restarts.

Our Terraform script is already creating a GCS bucket for us. Let's configure Rails to use it.

1. Checkout the next branch:
   ```bash
   git checkout workshop_2_cloud_storage
   ```
2. Open `config/storage.yml` and look at the `google` service definition. We use the `google-cloud-storage` gem to connect to our bucket.
3. Open `config/environments/production.rb` (and `development.rb` if you want to test locally) and change the ActiveStorage service:
   ```ruby
   config.active_storage.service = :google
   ```

Restart your Rails server and try creating a new post with an image. The image is now safely stored in a Google Cloud Storage bucket!

## Step 3: Cloud SQL

Check your Terraform output in the other terminal. If it's finished, you now have a fully managed PostgreSQL database!

Let's switch our application from SQLite to Cloud SQL.

1. Checkout the next branch:
   ```bash
   git checkout workshop_3_cloud_sql
   ```
2. We need to connect to our new Cloud SQL instance. In production, Cloud Run handles this natively. Locally, we will use the **Cloud SQL Auth Proxy** to securely connect to our database.
3. Open `config/database.yml`. Notice how the `production` block is now configured to use the `postgresql` adapter and expects a `DATABASE_URL` environment variable.

## Step 4: Secret Manager

Security is critical. We have a database password and a `RAILS_MASTER_KEY` (used to decrypt Rails credentials) that we cannot check into version control.

Instead of relying on fragile `.env` files in production, we will use **Google Cloud Secret Manager**.

1. Checkout the next branch:
   ```bash
   git checkout workshop_4_secret_manager
   ```
2. Our Terraform script created two empty secrets: `rails-master-key` and `rails-db-password`.
3. Let's populate them! Use the `gcloud` CLI to add your actual `master.key` content to Secret Manager:

```bash
gcloud secrets versions add rails-master-key --data-file=config/master.key
```

Now, when we deploy our app, Cloud Run will automatically fetch this secret and inject it into our container as an environment variable!

## Step 5: Cloud Run Deployment

It's time to take our blog live! We will deploy the application to Google Cloud Run, a fully managed serverless platform.

1. Checkout the next branch:
   ```bash
   git checkout workshop_5_cloud_run_classic
   ```
2. We will use the `gcloud run deploy` command to build our container and deploy it in one step. 

```bash
gcloud run deploy rails-blog \
  --source . \
  --region us-central1 \
  --allow-unauthenticated \
  --set-secrets="RAILS_MASTER_KEY=rails-master-key:latest"
```

Once the deployment finishes, click the URL provided in the terminal. Your Rails 8 blog is now live on the internet, backed by Cloud SQL and Cloud Storage!

## Step 6: Automating with Cloud Build

Deploying from your laptop is great for testing, but in a real team, you want deployments to happen automatically when you push to GitHub.

1. Checkout the next branch:
   ```bash
   git checkout workshop_6_cloud_build_cicd
   ```
2. Take a look at the `cloudbuild.yaml` file. This file tells Google Cloud Build exactly how to build our Docker container, run our database migrations, and deploy to Cloud Run.
3. In the Google Cloud Console, we will set up a Cloud Build Trigger connected to our GitHub repository. 

Now, every time you `git push main`, your application will automatically build and deploy!

## Step 7: AI Features and Background Jobs

Rails 8 introduced **Solid Queue**, a powerful database-backed job queue. We are going to use it to power a magical AI feature: **The "NanoBanana" Auto-Cover Generator**.

1. Checkout our final branch:
   ```bash
   git checkout workshop_7_ai_features
   ```

### The Architecture
Instead of making the user wait while we call the Gemini API, we offload the work to a background job. In a Cloud Run environment, this means we deploy the *same* container twice:
- **Service A (Web):** Listens for HTTP traffic.
- **Service B (Worker):** Runs `bundle exec rails solid_queue:start` and processes background jobs.

### The AI Magic
When you publish a post without a cover image, our `GenerateCoverImageJob` is triggered. 
1. It sends your article text to the Gemini/Imagen model using this prompt:
> *"Create a cover image for a blog post titled [Title]. The article contains the following text: [Text]. CRITICAL STYLE INSTRUCTION: The image MUST be rendered in the style of a 'Locandina di un film 1960' (a vintage 1960s Italian movie poster). Maintain a beautiful, cohesive vintage Italian cinematic aesthetic. Also, you MUST feature a banana somewhere in the scene."*
2. The job downloads the generated image and attaches it to the post via ActiveStorage.

Try it out! Create a new post, leave the image blank, and watch as an AI-generated, perfectly themed cover image appears a few seconds later.

## Conclusion

Congratulations! 🎉 

You've successfully migrated a local Rails 8 application to a production-grade architecture on Google Cloud. 

You've learned how to:
- Use **Cloud Storage** for scalable file uploads.
- Provision and connect to **Cloud SQL**.
- Securely manage credentials with **Secret Manager**.
- Deploy serverless containers with **Cloud Run**.
- Automate CI/CD pipelines with **Cloud Build**.
- Leverage **Solid Queue** and **Gemini** to build robust, asynchronous AI features.

### Extra Credit
If you want to keep exploring, check out our `IDEAS.md` for advanced challenges, such as:
- Deploying the app on a single VM using **Kamal**.
- Building a **Multi-language Podcastifier** that uses Cloud Translation and Text-to-Speech to generate localized audio versions of your blog posts!
