# Setup and Prerequisites

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

