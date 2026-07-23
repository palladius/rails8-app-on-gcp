#!/bin/bash
set -e

echo "Testing template generation..."

cat <<EOF > test_template.tf
locals {
  rendered = templatefile("../README.md.tftpl", {
    project_id = "test-project"
    region = "us-central1"
    gcs_dev_name = "test-project-activestorage-dev"
    gcs_test_name = "test-project-activestorage-test"
    gcs_prod_name = "test-project-activestorage-prod"
    sql_instance_name = "test-project-db"
    sql_database_name = "rails_production"
    sql_connection_name = "test-project:us-central1:test-project-db"
    sql_user_name = "rails_user"
    cloud_run_service_name = "test-project-rails-app"
    cloud_run_service_uri = "https://test-project-rails-app-xyz.a.run.app"
  })
}

output "rendered_template" {
  value = local.rendered
}
EOF

terraform init > /dev/null 2>&1
terraform apply -auto-approve > /dev/null 2>&1 || true
output=$(terraform output -raw rendered_template 2>/dev/null || echo "failed")

rm test_template.tf

if [[ "$output" == *"failed"* ]] || [[ -z "$output" ]]; then
  echo "Test failed! Template rendering failed. Does README.md.tftpl exist?"
  exit 1
elif [[ "$output" == *"🚀 Rails 8 GCP Infrastructure"* ]]; then
  echo "Test passed!"
  exit 0
else
  echo "Test failed! Output did not match."
  echo "$output"
  exit 1
fi
