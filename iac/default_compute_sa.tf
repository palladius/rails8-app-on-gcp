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
# The wait itself is iac/bin/wait-for-default-compute-sa.sh (retries only on "not found").
# Every resource that names that SA depends on this waiter
# (enforced by test/test_iac_codelab_contracts.rb).
###############################################################################

# NOTE: this deliberately does NOT enable compute.googleapis.com. The SA appears a few seconds
# after the first APIs are enabled even with Compute Engine disabled (see #164), and enabling
# Compute Engine on a new project typically creates the permissive `default` VPC (open SSH/RDP
# firewall rules), which this workshop's security posture avoids.
resource "terraform_data" "wait_for_default_compute_sa" {
  triggers_replace = [var.project_id]

  provisioner "local-exec" {
    command = "${path.module}/bin/wait-for-default-compute-sa.sh ${data.google_project.current.number}-compute@developer.gserviceaccount.com ${var.project_id}"
  }

  # In #164 the SA appeared shortly after the first APIs (run, cloudbuild, ...) were enabled.
  depends_on = [
    google_project_service.cloudbuild,
    google_project_service.artifactregistry,
  ]
}
