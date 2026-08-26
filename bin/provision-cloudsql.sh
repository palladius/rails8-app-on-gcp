#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# Rails 8 on GCP Workshop - Cloud SQL Quick Provisioning Helper
# ------------------------------------------------------------------------------

echo "🚀 [Workshop Step 0] Starting Background Cloud SQL Provisioning..."

PROJECT_ID="${GCP_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null || echo '')}"
REGION="${GCP_REGION:-us-central1}"

if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "(unset)" ]]; then
  echo "❌ Error: No Google Cloud Project ID detected."
  echo "Please set your project using: gcloud config set project <YOUR_PROJECT_ID>"
  echo "Or run: export GCP_PROJECT_ID=<YOUR_PROJECT_ID>"
  exit 1
fi

echo "📦 Project ID : $PROJECT_ID"
echo "🌍 Region     : $REGION"

# Check if Terraform is available in iac/
if [[ -d "iac" ]] && command -v terraform &>/dev/null; then
  echo "🛠️ Provisioning via Terraform in iac/..."
  (
    cd iac
    terraform init -upgrade
    terraform apply -auto-approve -var="project_id=${PROJECT_ID}" -var="region=${REGION}"
  )
  echo "✅ Terraform provisioning complete!"
else
  # Fallback to direct gcloud CLI async provisioning
  INSTANCE_NAME="rails8-db-${RANDOM}"
  echo "⚡ Provisioning Cloud SQL PostgreSQL instance '${INSTANCE_NAME}' asynchronously via gcloud..."
  
  gcloud sql instances create "${INSTANCE_NAME}" \
    --project="${PROJECT_ID}" \
    --database-version=POSTGRES_15 \
    --tier=db-f1-micro \
    --region="${REGION}" \
    --async

  echo "⏳ Cloud SQL instance creation started in the background (takes ~10-12 mins)."
  echo "💡 Instance Name: ${INSTANCE_NAME}"
  echo "👉 You can continue with Step 1 while the database provisions!"
fi
