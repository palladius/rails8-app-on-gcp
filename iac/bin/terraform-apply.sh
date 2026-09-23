#!/usr/bin/env bash
# ==============================================================================
# Robust Terraform apply wrapper for Rails 8 on GCP workshop.
# Automatically bridges .env variables into Terraform TF_VAR_* environment.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IAC_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${IAC_DIR}/.." && pwd)"

# 1. Source .env if present (check repo root first, then iac/)
if [ -f "${REPO_ROOT}/.env" ]; then
    echo "📄 Sourcing environment from ${REPO_ROOT}/.env..."
    set -a
    # shellcheck disable=SC1091
    source "${REPO_ROOT}/.env"
    set +a
elif [ -f "${IAC_DIR}/.env" ]; then
    echo "📄 Sourcing environment from ${IAC_DIR}/.env..."
    set -a
    # shellcheck disable=SC1091
    source "${IAC_DIR}/.env"
    set +a
fi

# 2. Resolve Project and Region with smart fallbacks
PROJECT_ID="${GOOGLE_CLOUD_PROJECT:-$(gcloud config get-value project 2>/dev/null || true)}"
REGION="${GOOGLE_CLOUD_REGION:-europe-west1}"

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
    echo "❌ Error: GOOGLE_CLOUD_PROJECT is unset and no active gcloud project found!"
    echo "   Please run: gcloud config set project <PROJECT_ID>"
    exit 1
fi

echo "🚀 Preparing Terraform for Project: ${PROJECT_ID} (Region: ${REGION})..."

# 3. Map .env to TF_VAR_* so Terraform natively consumes them
export TF_VAR_project_id="${PROJECT_ID}"
export TF_VAR_region="${REGION}"
export TF_VAR_admin_account="${GOOGLE_CLOUD_ACCOUNT:-$(gcloud config get-value account 2>/dev/null || true)}"

if [ -n "${IAP_ALLOWED_USERS:-}" ]; then
    # Convert comma-separated string to HCL list format: '["u1", "u2"]'
    TF_USERS=$(python3 -c "import json, os; print(json.dumps([u.strip() for u in os.environ.get('IAP_ALLOWED_USERS', '').split(',') if u.strip()]))")
    export TF_VAR_iap_allowed_users="${TF_USERS}"
fi

# Map DEVELOPERS from .env if present, otherwise default to current admin identity
if [ -n "${DEVELOPERS:-}" ]; then
    TF_DEVS=$(python3 -c "import json, os; print(json.dumps([d.strip() for d in os.environ.get('DEVELOPERS', '').split(',') if d.strip()]))")
    export TF_VAR_developers="${TF_DEVS}"
elif [ -n "${TF_VAR_admin_account}" ]; then
    export TF_VAR_developers="[\"user:${TF_VAR_admin_account}\"]"
fi

# 4. Ensure remote state bucket exists
"${SCRIPT_DIR}/create-tfstate-bucket.sh"

# 5. Initialize and apply Terraform
cd "${IAC_DIR}"
echo "🔧 Initializing Terraform backend..."
terraform init -backend-config="bucket=${PROJECT_ID}-tfstate"

echo "⚡ Applying Terraform changes..."
terraform apply -auto-approve

echo "🎉 Terraform apply completed successfully!"
