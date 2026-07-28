###############################################################################
# Secrets: Secret Manager for Rails app secrets
###############################################################################

# DB Password
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

# Rails Master Key
resource "google_secret_manager_secret" "rails_master_key" {
  secret_id = "rails-master-key"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "rails_master_key" {
  secret      = google_secret_manager_secret.rails_master_key.id
  secret_data = "dummy-key-replace-me"
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
}

resource "google_secret_manager_secret_version" "admin_password" {
  secret      = google_secret_manager_secret.admin_password.id
  secret_data = random_password.admin_password.result
}
