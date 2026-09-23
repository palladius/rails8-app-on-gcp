#!/usr/bin/env bash
# ==============================================================================
# Idempotently create Google Cloud Storage bucket for Terraform remote state.
# ==============================================================================
set -euo pipefail

# Fall back to active gcloud config if environment variables are not set
PROJECT_ID="${GOOGLE_CLOUD_PROJECT:-$(gcloud config get-value project 2>/dev/null || true)}"
REGION="${GOOGLE_CLOUD_REGION:-europe-west1}"

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
    echo "❌ Error: GOOGLE_CLOUD_PROJECT is unset and no active gcloud project found!"
    echo "   Please run: gcloud config set project <PROJECT_ID>"
    exit 1
fi

BUCKET="gs://${PROJECT_ID}-tfstate"

echo "📦 Ensuring Terraform state bucket exists: $BUCKET ($REGION)..."
gcloud storage buckets create "$BUCKET" --location="$REGION" 2>/dev/null || \
    gcloud storage buckets describe "$BUCKET" --format="value(name)" >/dev/null

echo "✅ Terraform state bucket ready: $BUCKET"
