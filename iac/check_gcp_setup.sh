#!/bin/bash
# iac/check_gcp_setup.sh
# Verifies GCP setup for rails8-app-on-gcp

set -e

if [ -f "../.env" ]; then
  source ../.env
fi

if [ -z "$GOOGLE_CLOUD_PROJECT" ]; then
  PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
else
  PROJECT_ID=$GOOGLE_CLOUD_PROJECT
fi

if [ -f "../private/${PROJECT_ID}-key.json" ]; then
  export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/../private/${PROJECT_ID}-key.json"
  echo "🔑 Using project-specific JSON key for authentication"
fi

echo "🔍 Checking GCP setup for project: $PROJECT_ID"

echo -e "\n=== 1️⃣ Checking ActiveStorage GCS Buckets ==="
for env in dev test prod; do
  BUCKET_NAME="${PROJECT_ID}-activestorage-${env}"
  if gcloud storage ls "gs://${BUCKET_NAME}" &>/dev/null; then
    echo "  ✅ Bucket gs://${BUCKET_NAME} exists."
    # Count media. We suppress errors and count lines.
    COUNT=$(gcloud storage ls "gs://${BUCKET_NAME}/**" 2>/dev/null | wc -l | tr -d ' ')
    echo "     📊 Media in $env: $COUNT"
  else
    echo "  ❌ Bucket gs://${BUCKET_NAME} DOES NOT exist or access denied!"
  fi
done

echo -e "\n=== 2️⃣ Checking Cloud Run Service Account ==="
SA_EMAIL="rails-cloudrun-sa@${PROJECT_ID}.iam.gserviceaccount.com"
if gcloud iam service-accounts describe "$SA_EMAIL" &>/dev/null; then
  echo "  ✅ Service Account $SA_EMAIL exists."
else
  echo "  ❌ Service Account $SA_EMAIL DOES NOT exist!"
fi

echo -e "\n=== 3️⃣ Checking Secret Manager for RAILS_MASTER_KEY ==="
if gcloud secrets describe "rails-master-key" &>/dev/null; then
  echo "  ✅ Secret 'rails-master-key' exists."
else
  echo "  ❌ Secret 'rails-master-key' DOES NOT exist!"
fi

echo "🎉 GCP Verification complete."

echo -e "\n=== 4️⃣ Checking Terraform State GCS Bucket ==="
TF_BUCKET="${PROJECT_ID}-tfstate"
if gcloud storage ls "gs://${TF_BUCKET}" &>/dev/null; then
  echo "  ✅ TF State Bucket gs://${TF_BUCKET} exists."
else
  echo "  ❌ TF State Bucket gs://${TF_BUCKET} DOES NOT exist!"
fi
