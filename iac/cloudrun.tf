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
      "roles/secretmanager.secretAccessor"
    ]
  }
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
