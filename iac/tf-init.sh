#!/bin/bash
# iac/tf-init.sh
set -e

# Load project ID from .env
if [ -f "../.env" ]; then
  source ../.env
else
  echo "❌ Error: ../.env not found!"
  exit 1
fi

if [ -z "$GOOGLE_CLOUD_PROJECT" ]; then
  echo "❌ Error: GOOGLE_CLOUD_PROJECT not set in .env"
  exit 1
fi

BUCKET_NAME="${GOOGLE_CLOUD_PROJECT}-tfstate"

echo "🔍 Checking if Terraform state bucket exists: gs://$BUCKET_NAME"
if ! gcloud storage ls "gs://$BUCKET_NAME" &>/dev/null; then
  echo "🚀 Creating bucket gs://$BUCKET_NAME for Terraform state..."
  gcloud storage buckets create "gs://$BUCKET_NAME" --project="$GOOGLE_CLOUD_PROJECT" --location="EUROPE-WEST1" --uniform-bucket-level-access
else
  echo "✅ Bucket gs://$BUCKET_NAME already exists."
fi

echo "🔧 Initializing Terraform with GCS backend..."
terraform init -backend-config="bucket=$BUCKET_NAME" -force-copy
