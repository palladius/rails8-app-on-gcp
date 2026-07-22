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

resource "random_password" "db_password" {
  length  = 16
  special = false
}

# Cloud SQL PostgreSQL Instance
resource "google_sql_database_instance" "main" {
  name             = "${var.project_id}-db"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled = true
    }
  }

  deletion_protection = false # Workshop-friendly
}

resource "google_sql_database" "database" {
  name     = "rails_production"
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "rails_user" {
  name     = "rails_user"
  instance = google_sql_database_instance.main.name
  password = random_password.db_password.result
}

# Store the DB Password in Secret Manager
resource "google_secret_manager_secret" "db_password" {
  secret_id = "rails-db-password"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

# Cloud Run Service (Rails App)
resource "google_cloud_run_v2_service" "rails_app" {
  name     = "${var.project_id}-rails-app"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = module.service_account_cloud_run.email

    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello" # Placeholder until Cloud Build pushes

      env {
        name  = "DATABASE_URL"
        value = "postgres://${google_sql_user.rails_user.name}:${random_password.db_password.result}@localhost:5432/${google_sql_database.database.name}?host=/cloudsql/${google_sql_database_instance.main.connection_name}"
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.main.connection_name]
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      client,
      client_version,
    ]
  }
}

resource "google_cloud_run_v2_service_iam_member" "public_access" {
  project  = google_cloud_run_v2_service.rails_app.project
  location = google_cloud_run_v2_service.rails_app.location
  name     = google_cloud_run_v2_service.rails_app.name
  role     = "roles/run.invoker"
  member   = "allUsers"
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

    ## 🐘 Cloud SQL (PostgreSQL)
    * **Instance**: [${google_sql_database_instance.main.name}](https://console.cloud.google.com/sql/instances/${google_sql_database_instance.main.name}/overview?project=${var.project_id})
    * **Database**: ${google_sql_database.database.name}
    * **Connection Name**: `${google_sql_database_instance.main.connection_name}`
    * **DB User**: `${google_sql_user.rails_user.name}`

    ## 🏃 Cloud Run
    * **Service**: [${google_cloud_run_v2_service.rails_app.name}](https://console.cloud.google.com/run/detail/${var.region}/${google_cloud_run_v2_service.rails_app.name}/metrics?project=${var.project_id})
    * **URL**: [${google_cloud_run_v2_service.rails_app.uri}](${google_cloud_run_v2_service.rails_app.uri})

    ## 🔐 Secret Manager
    * **rails-master-key**: [View in Secret Manager](https://console.cloud.google.com/security/secret-manager/secret/rails-master-key/versions?project=${var.project_id})
    * **rails-db-password**: [View in Secret Manager](https://console.cloud.google.com/security/secret-manager/secret/rails-db-password/versions?project=${var.project_id})
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
          code { background: #e0e0e0; padding: 2px 4px; border-radius: 3px; }
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

        <h2>🐘 Cloud SQL (PostgreSQL)</h2>
        <ul>
          <li><strong>Instance</strong>: <a href="https://console.cloud.google.com/sql/instances/${google_sql_database_instance.main.name}/overview?project=${var.project_id}">${google_sql_database_instance.main.name}</a></li>
          <li><strong>Database</strong>: ${google_sql_database.database.name}</li>
          <li><strong>Connection Name</strong>: <code>${google_sql_database_instance.main.connection_name}</code></li>
          <li><strong>DB User</strong>: <code>${google_sql_user.rails_user.name}</code></li>
        </ul>

        <h2>🏃 Cloud Run</h2>
        <ul>
          <li><strong>Service</strong>: <a href="https://console.cloud.google.com/run/detail/${var.region}/${google_cloud_run_v2_service.rails_app.name}/metrics?project=${var.project_id}">${google_cloud_run_v2_service.rails_app.name}</a></li>
          <li><strong>URL</strong>: <a href="${google_cloud_run_v2_service.rails_app.uri}">${google_cloud_run_v2_service.rails_app.uri}</a></li>
        </ul>

        <h2>🔐 Secret Manager</h2>
        <ul>
          <li><strong>rails-master-key</strong>: <a href="https://console.cloud.google.com/security/secret-manager/secret/rails-master-key/versions?project=${var.project_id}">View in Secret Manager</a></li>
          <li><strong>rails-db-password</strong>: <a href="https://console.cloud.google.com/security/secret-manager/secret/rails-db-password/versions?project=${var.project_id}">View in Secret Manager</a></li>
        </ul>
      </body>
    </html>
  EOT
}
