###############################################################################
# Database: Cloud SQL PostgreSQL + User
###############################################################################

resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "random_id" "db_suffix" {
  byte_length = 2
}

# Required GCP API for Cloud SQL Admin
resource "google_project_service" "sqladmin" {
  project            = var.project_id
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

# Cloud SQL PostgreSQL Instance
resource "google_sql_database_instance" "main" {
  name             = "rails8-app-on-gcp-${random_id.db_suffix.hex}"
  database_version = "POSTGRES_15"
  region           = var.region

  depends_on = [google_project_service.sqladmin]

  settings {
    tier = "db-f1-micro"
    user_labels = {
      "managed-by" = "terraform"
    }
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
