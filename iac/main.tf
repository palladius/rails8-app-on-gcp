terraform {
  backend "gcs" {
    prefix = "terraform/state"
  }
  required_version = ">= 1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Development Bucket
module "gcs_dev" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gcs?ref=v34.0.0"
  project_id    = var.project_id
  name          = "${var.project_id}-activestorage-dev"
  location      = var.region
  force_destroy = true
}

# Test Bucket
module "gcs_test" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gcs?ref=v34.0.0"
  project_id    = var.project_id
  name          = "${var.project_id}-activestorage-test"
  location      = var.region
  force_destroy = true
}

# Production Bucket
module "gcs_prod" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gcs?ref=v34.0.0"
  project_id = var.project_id
  name       = "${var.project_id}-activestorage-prod"
  location   = var.region
}

# Seed Images for ActiveStorage End-to-End Testing
resource "google_storage_bucket_object" "dev_seed_image" {
  name   = "seeds/gcs_dev_image.jpg"
  bucket = module.gcs_dev.name
  source = "../blog/app/assets/images/gcs_dev_image.jpg"
}

resource "google_storage_bucket_object" "test_seed_image" {
  name   = "seeds/gcs_test_image.jpg"
  bucket = module.gcs_test.name
  source = "../blog/app/assets/images/gcs_test_image.jpg"
}

resource "google_storage_bucket_object" "prod_seed_image" {
  name   = "seeds/gcs_prod_image.jpg"
  bucket = module.gcs_prod.name
  source = "../blog/app/assets/images/gcs_prod_image.jpg"
}

# Cloud Run Service Account
module "service_account_cloud_run" {
  source       = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v34.0.0"
  project_id   = var.project_id
  name         = "rails-cloudrun-sa"
  display_name = "Cloud Run Service Account for Rails App"
  iam_project_roles = {
    "${var.project_id}" = [
      "roles/storage.objectAdmin"
    ]
  }
}

resource "local_file" "readme_md" {
  filename = "${path.module}/out/README.md"
  content  = <<-EOT
    # 🚀 Rails 8 GCP Infrastructure

    Welcome to your dynamically generated infrastructure output!

    ## 🪣 ActiveStorage Buckets
    * 🟡 **Dev**: [gs://${module.gcs_dev.name}](https://console.cloud.google.com/storage/browser/${module.gcs_dev.name}?project=${var.project_id})
    * 🔵 **Test**: [gs://${module.gcs_test.name}](https://console.cloud.google.com/storage/browser/${module.gcs_test.name}?project=${var.project_id})
    * 🟢 **Prod**: [gs://${module.gcs_prod.name}](https://console.cloud.google.com/storage/browser/${module.gcs_prod.name}?project=${var.project_id})

    ## 🔐 Secret Manager
    * **rails-master-key**: [View in Secret Manager](https://console.cloud.google.com/security/secret-manager/secret/rails-master-key/versions?project=${var.project_id})

    *(Cloud SQL and Cloud Run links will appear here once we add them to Terraform!)*
  EOT
}

resource "local_file" "readme_html" {
  filename = "${path.module}/out/OUTPUT.html"
  content  = <<-EOT
    <html>
      <head>
        <title>Rails 8 GCP Infrastructure</title>
        <style>
          body { font-family: sans-serif; margin: 40px; line-height: 1.6; }
          h1 { color: #d32f2f; }
          h2 { color: #1976d2; border-bottom: 2px solid #1976d2; padding-bottom: 5px; }
          ul { list-style-type: none; padding-left: 0; }
          li { margin-bottom: 10px; padding: 10px; background: #f5f5f5; border-radius: 5px; }
          a { color: #00796b; text-decoration: none; font-weight: bold; }
          a:hover { text-decoration: underline; }
        </style>
      </head>
      <body>
        <h1>🚀 Rails 8 GCP Infrastructure</h1>
        <p>Welcome to your dynamically generated infrastructure output!</p>

        <h2>🪣 ActiveStorage Buckets</h2>
        <ul>
          <li>🟡 <strong>Dev</strong>: <a href="https://console.cloud.google.com/storage/browser/${module.gcs_dev.name}?project=${var.project_id}">gs://${module.gcs_dev.name}</a></li>
          <li>🔵 <strong>Test</strong>: <a href="https://console.cloud.google.com/storage/browser/${module.gcs_test.name}?project=${var.project_id}">gs://${module.gcs_test.name}</a></li>
          <li>🟢 <strong>Prod</strong>: <a href="https://console.cloud.google.com/storage/browser/${module.gcs_prod.name}?project=${var.project_id}">gs://${module.gcs_prod.name}</a></li>
        </ul>

        <h2>🔐 Secret Manager</h2>
        <ul>
          <li><strong>rails-master-key</strong>: <a href="https://console.cloud.google.com/security/secret-manager/secret/rails-master-key/versions?project=${var.project_id}">View in Secret Manager</a></li>
        </ul>

        <p><em>(Cloud SQL and Cloud Run links will appear here once we add them to Terraform!)</em></p>
      </body>
    </html>
  EOT
}
