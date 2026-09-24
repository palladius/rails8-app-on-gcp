###############################################################################
# Secrets: Secret Manager for Rails app secrets
###############################################################################

# Required GCP API for Secret Manager
resource "google_project_service" "secretmanager" {
  project            = var.project_id
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

# DB Password
resource "google_secret_manager_secret" "db_password" {
  secret_id = "rails-db-password"
  replication {
    auto {}
  }
  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

# Rails Master Key
resource "random_id" "rails_master_key" {
  byte_length = 16
}

resource "google_secret_manager_secret" "rails_master_key" {
  secret_id = "rails-master-key"
  replication {
    auto {}
  }
  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "rails_master_key" {
  secret      = google_secret_manager_secret.rails_master_key.id
  secret_data = trimspace(file("${path.module}/../blog/config/master.key"))

  lifecycle {
    precondition {
      condition     = fileexists("${path.module}/../blog/config/master.key") && can(regex("^[0-9a-f]{32}$", trimspace(file("${path.module}/../blog/config/master.key")))) && !startswith(trimspace(file("${path.module}/../blog/config/master.key")), "0123456789abcdef")
      error_message = "blog/config/master.key is missing or dummy! Run: ruby ../bin/ensure_workshop_credentials.rb (or use ./bin/terraform-apply.sh)"
    }
  }
}

# Admin Password
resource "random_password" "admin_password" {
  length  = 16
  special = false
}

resource "google_secret_manager_secret" "admin_password" {
  secret_id = "rails-admin-password"
  replication {
    auto {}
  }
  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "admin_password" {
  secret      = google_secret_manager_secret.admin_password.id
  secret_data = random_password.admin_password.result
}

# Explicit secret-level IAM bindings so `gcloud secrets get-iam-policy rails-master-key`
# (Step 5.4) returns the expected policy table for $RUN_SA (rails-cloudrun-sa) and
# also works seamlessly when `gcloud run compose up` boots with Default Compute SA.
locals {
  runtime_secret_accessors = {
    rails_cloudrun_sa  = module.service_account_cloud_run.iam_email
    default_compute_sa = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
  }
}

resource "google_secret_manager_secret_iam_member" "rails_master_key_access" {
  for_each  = local.runtime_secret_accessors
  project   = var.project_id
  secret_id = google_secret_manager_secret.rails_master_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = each.value
}

resource "google_secret_manager_secret_iam_member" "db_password_access" {
  for_each  = local.runtime_secret_accessors
  project   = var.project_id
  secret_id = google_secret_manager_secret.db_password.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = each.value
}

resource "google_secret_manager_secret_iam_member" "admin_password_access" {
  for_each  = local.runtime_secret_accessors
  project   = var.project_id
  secret_id = google_secret_manager_secret.admin_password.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = each.value
}

