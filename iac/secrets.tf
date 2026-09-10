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
resource "google_secret_manager_secret" "rails_master_key" {
  secret_id = "rails-master-key"
  replication {
    auto {}
  }
  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "rails_master_key" {
  secret      = google_secret_manager_secret.rails_master_key.id
  secret_data = fileexists("${path.module}/../blog/config/master.key") ? file("${path.module}/../blog/config/master.key") : "0123456789abcdef0123456789abcdef"
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
