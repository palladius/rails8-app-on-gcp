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

# Cloud SQL PostgreSQL Instance
resource "google_sql_database_instance" "main" {
  name             = "rails8-app-on-gcp-${random_id.db_suffix.hex}"
  database_version = "POSTGRES_15"
  region           = var.region

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
