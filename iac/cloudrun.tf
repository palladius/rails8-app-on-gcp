###############################################################################
# Cloud Run: Service + IAM + Service Account
###############################################################################

data "google_project" "current" {
  project_id = var.project_id
}

# Cloud Run Service Account (Least-Privilege: secret access is scoped per-secret in secrets.tf,
# and storage access is scoped per-bucket via google_storage_bucket_iam_member below)
module "service_account_cloud_run" {
  source       = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v34.0.0"
  project_id   = var.project_id
  name         = "rails-cloudrun-sa"
  display_name = "Cloud Run Service Account for Rails App"
  iam_project_roles = {
    "${var.project_id}" = [
      "roles/cloudsql.client",
      "roles/aiplatform.user" # Nano Banana cover generation on Vertex AI (issue #18)
    ]
  }
}

# Also grant minimal runtime roles to the Default Compute Service Account
# (${PROJECT_NUMBER}-compute@developer.gserviceaccount.com) because
# `gcloud run compose up` uses a hardcoded Go template without `serviceAccountName:`
# and temporarily boots the initial revision under Default Compute SA before
# `gcloud run services update blog --service-account=$RUN_SA` runs.
resource "google_project_iam_member" "default_compute_sa_runtime_roles" {
  for_each = toset([
    "roles/cloudsql.client",
    "roles/aiplatform.user",
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

# Bucket-scoped ActiveStorage IAM bindings (fixes M4 — avoids project-wide storage.objectAdmin sprawl)
locals {
  activestorage_buckets = {
    dev  = module.gcs_dev.name
    test = module.gcs_test.name
    prod = module.gcs_prod.name
  }
}

resource "google_storage_bucket_iam_member" "rails_sa_bucket_object_admin" {
  for_each = local.activestorage_buckets
  bucket   = each.value
  role     = "roles/storage.objectAdmin"
  member   = module.service_account_cloud_run.iam_email
}

resource "google_storage_bucket_iam_member" "default_compute_sa_bucket_object_admin" {
  for_each = local.activestorage_buckets
  bucket   = each.value
  role     = "roles/storage.objectAdmin"
  member   = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

# Required GCP API for Cloud Run
resource "google_project_service" "run" {
  project            = var.project_id
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

# GenerateCoverImageJob asks Vertex AI (gemini-2.5-flash-image, "Nano Banana")
# for a cover image whenever a post is saved without one. Authentication is
# Application Default Credentials only — the Cloud Run service account above,
# or the developer's own `gcloud auth application-default login` on a laptop —
# so no API key ever lands in .env or Secret Manager. Without the API enabled
# and roles/aiplatform.user, the app quietly attaches a bundled "fake" cover
# instead of failing. See issue #18.
resource "google_project_service" "aiplatform" {
  project            = var.project_id
  service            = "aiplatform.googleapis.com"
  disable_on_destroy = false
}

# Let developers generate covers locally with their own ADC.
resource "google_project_iam_member" "developer_vertex_user" {
  for_each = toset(var.developers)
  project  = var.project_id
  role     = "roles/aiplatform.user"
  member   = each.value
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

# Self-scoped TokenCreator on Default Compute SA (fixes m4 — no cross-SA impersonation on rails-cloudrun-sa)
resource "google_service_account_iam_member" "default_compute_sa_self_signer" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${data.google_project.current.number}-compute@developer.gserviceaccount.com"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
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

      env {
        name  = "GOOGLE_CLOUD_ACCOUNT"
        value = var.admin_account != "" ? var.admin_account : (length(var.developers) > 0 ? replace(var.developers[0], "user:", "") : "admin@example.com")
      }

      env {
        name  = "GOOGLE_CLOUD_PROJECT"
        value = var.project_id
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

  depends_on = [
    google_project_service.run,
    google_project_service.sqladmin,
  ]
}

# ==============================================================================
# 🔐 Cloud Run Access Architecture:
# ------------------------------------------------------------------------------
# 👉 WORKSHOP MODE (Default):
#    We grant 'roles/run.invoker' to specific authenticated accounts in
#    'var.iap_allowed_users'. This avoids breaking under corporate Org Policies
#    (e.g., constraints/iam.allowedPolicyMemberDomains blocking allUsers).
#
# 👉 OPTIONAL PUBLIC MODE:
#    Set 'allow_unauthenticated = true' if running in a personal unmanaged GCP
#    project where public unauthenticated web access is desired.
#
# 👉 PRODUCTION HARDENED ZERO-TRUST MODE (Step 8):
#    For enterprise security, enable IAP by setting 'enable_iap = true' (iac/iap.tf).
#    This routes all traffic through an HTTPS Application Load Balancer protected
#    by Identity-Aware Proxy (IAP) and OAuth2 consent, keeping Cloud Run ingress
#    restricted to internal-and-cloud-load-balancing only.
# ==============================================================================

# Public access (only if explicitly enabled and not blocked by Org Policy)
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  count    = var.allow_unauthenticated ? 1 : 0
  project  = google_cloud_run_v2_service.rails_app.project
  location = google_cloud_run_v2_service.rails_app.location
  name     = google_cloud_run_v2_service.rails_app.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Authenticated invoker access for workshop attendees (safe under Org Policy)
resource "google_cloud_run_v2_service_iam_member" "authenticated_invokers" {
  for_each = toset(var.iap_allowed_users)
  project  = google_cloud_run_v2_service.rails_app.project
  location = google_cloud_run_v2_service.rails_app.location
  name     = google_cloud_run_v2_service.rails_app.name
  role     = "roles/run.invoker"
  member   = "user:${each.value}"
}

