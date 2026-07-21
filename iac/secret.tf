# Secret Manager for Rails Master Key
module "secret_manager" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/secret-manager?ref=v34.0.0"
  project_id = var.project_id
  secrets = {
    "rails-master-key" = {
      locations = [var.region]
    }
  }
  iam = {
    "rails-master-key" = {
      "roles/secretmanager.secretAccessor" = [
        "serviceAccount:${module.service_account_cloud_run.email}"
      ]
    }
  }
}
