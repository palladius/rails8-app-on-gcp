###############################################################################
# Default Compute Service Account: wait for Google to create it (issue #164)
#
# Google creates `<PROJECT_NUMBER>-compute@developer.gserviceaccount.com`
# lazily, a few seconds AFTER the first APIs are enabled, not at project
# creation. Terraform binds roles to it in several places (cicd.tf, cloudrun.tf,
# secrets.tf), so on a fresh project those bindings used to race the creation
# and the very first `terraform apply` failed with
# "Service account ...-compute@developer.gserviceaccount.com does not exist".
#
# Every resource that names that SA depends on this waiter
# (enforced by test/test_iac_codelab_contracts.rb).
###############################################################################

# Enabling Compute Engine is what reliably provisions the Default Compute SA,
# and Cloud Run / Cloud Build rely on it in practice. Also used by iap.tf.
resource "google_project_service" "compute_api" {
  project            = var.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "terraform_data" "wait_for_default_compute_sa" {
  triggers_replace = [var.project_id]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      sa="${data.google_project.current.number}-compute@developer.gserviceaccount.com"
      echo "Waiting for the Default Compute Service Account $sa (Google creates it lazily)..."
      for _ in $(seq 1 36); do
        if gcloud iam service-accounts describe "$sa" --project="${var.project_id}" >/dev/null 2>&1; then
          echo "Default Compute Service Account is ready."
          exit 0
        fi
        sleep 5
      done
      echo "Timed out after 3 minutes waiting for $sa. Re-run 'just terraform-apply'." >&2
      exit 1
    EOT
  }

  depends_on = [
    google_project_service.compute_api,
    google_project_service.cloudbuild,
  ]
}
