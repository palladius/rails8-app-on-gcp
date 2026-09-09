###############################################################################
# CI/CD: Artifact Registry + Cloud Build Trigger
###############################################################################

# Required GCP API for Artifact Registry
resource "google_project_service" "artifactregistry" {
  project            = var.project_id
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# Artifact Registry for Docker images
resource "google_artifact_registry_repository" "docker" {
  location      = var.region
  repository_id = "rails8-gcp-app"
  description   = "Docker images for the Rails 8 GCP app"
  format        = "DOCKER"
  depends_on    = [google_project_service.artifactregistry]
}

# Dedicated Service Account for Cloud Build CI/CD (Least Privilege / POLA)
module "service_account_cloud_build" {
  count        = var.enable_cicd_trigger ? 1 : 0
  source       = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v34.0.0"
  project_id   = var.project_id
  name         = "rails-cloudbuild-sa"
  display_name = "Cloud Build Trigger SA (BYOSA)"
  iam_project_roles = {
    "${var.project_id}" = [
      "roles/logging.logWriter",
      "roles/artifactregistry.writer",
      "roles/run.developer",
    ]
  }
}

# Allow the Build SA to act as the Cloud Run runtime SA during deployments
resource "google_service_account_iam_member" "cloudbuild_acts_as_cloudrun" {
  count              = var.enable_cicd_trigger ? 1 : 0
  service_account_id = module.service_account_cloud_run.id
  role               = "roles/iam.serviceAccountUser"
  member             = module.service_account_cloud_build[0].iam_email
}

# Cloud Build Trigger — auto-deploys on push to main
# Substitutions are the "glue" between TF outputs and cloudbuild.yaml vars.
# Secrets (_RAILS_MASTER_KEY, _DATABASE_URL) are passed by bin/cloudbuild-submit
# for local testing, and by the trigger config for auto-deploy.
resource "google_cloudbuild_trigger" "deploy_on_push" {
  count           = var.enable_cicd_trigger ? 1 : 0
  name            = "on-commit-build-rails8-app-on-gcp"
  location        = "global"
  service_account = module.service_account_cloud_build[0].id

  github {
    owner = "palladius"
    name  = "rails8-app-on-gcp"
    push {
      branch = "^main$"
    }
  }

  filename = "cloudbuild.yaml"

  substitutions = {
    _AR_REGION = var.region
    _APP_NAME  = google_cloud_run_v2_service.rails_app.name
    _AR_REPO   = google_artifact_registry_repository.docker.repository_id
  }
}
