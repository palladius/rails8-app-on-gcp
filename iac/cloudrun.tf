###############################################################################
# Cloud Run: Service + IAM + Service Account
###############################################################################

# Cloud Run Service Account
module "service_account_cloud_run" {
  source       = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v34.0.0"
  project_id   = var.project_id
  name         = "rails-cloudrun-sa"
  display_name = "Cloud Run Service Account for Rails App"
  iam_project_roles = {
    "${var.project_id}" = [
      "roles/storage.objectAdmin",
      "roles/secretmanager.secretAccessor",
      "roles/cloudsql.client"
    ]
  }
}

# ActiveStorage signs GCS blob URLs through the IAM Credentials signBlob API
# (`iam: true` in blog/config/storage.yml), because Cloud Run's metadata server has
# no private key to sign with. That call needs the API enabled and the service
# account allowed to sign as itself — without either, every blob returns a 500.
# See issue #8.
resource "google_project_service" "iam_credentials" {
  project            = var.project_id
  service            = "iamcredentials.googleapis.com"
  disable_on_destroy = false
}

resource "google_service_account_iam_member" "cloud_run_sa_signer" {
  service_account_id = module.service_account_cloud_run.id
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = module.service_account_cloud_run.iam_email
}

# Allow developers to sign GCS blob URLs locally via `iam: true` in storage.yml.
# Without this, running ACTIVE_STORAGE_SERVICE=google_dev locally fails with
# "iam.serviceAccounts.signBlob denied". See issue #11.
resource "google_service_account_iam_member" "developer_sa_signer" {
  for_each           = toset(var.developers)
  service_account_id = module.service_account_cloud_run.id
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = each.value
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

      env {
        name = "DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "RAILS_MASTER_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.rails_master_key.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "ADMIN_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.admin_password.secret_id
            version = "latest"
          }
        }
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
