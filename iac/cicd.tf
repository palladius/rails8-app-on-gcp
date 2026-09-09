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

# Cloud Build Trigger — auto-deploys on push to main
# Substitutions are the "glue" between TF outputs and cloudbuild.yaml vars.
# Secrets (_RAILS_MASTER_KEY, _DATABASE_URL) are passed by bin/cloudbuild-submit
# for local testing, and by the trigger config for auto-deploy.
resource "google_cloudbuild_trigger" "deploy_on_push" {
  count           = var.enable_cicd_trigger ? 1 : 0
  name            = "on-commit-build-rails8-app-on-gcp"
  location        = "global"
  service_account = module.service_account_cloud_run.id

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
