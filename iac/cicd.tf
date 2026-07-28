###############################################################################
# CI/CD: Artifact Registry + Cloud Build Trigger
###############################################################################

# Artifact Registry for Docker images
resource "google_artifact_registry_repository" "docker" {
  location      = var.region
  repository_id = "rails8-gcp-app"
  description   = "Docker images for the Rails 8 GCP app"
  format        = "DOCKER"
}

# Cloud Build Trigger — auto-deploys on push to main
# Substitutions are the "glue" between TF outputs and cloudbuild.yaml vars.
# Secrets (_RAILS_MASTER_KEY, _DATABASE_URL) are passed by bin/cloudbuild-submit
# for local testing, and by the trigger config for auto-deploy.
resource "google_cloudbuild_trigger" "deploy_on_push" {
  name     = "on-commit-build-rails8-app-on-gcp"
  location = "global"

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
