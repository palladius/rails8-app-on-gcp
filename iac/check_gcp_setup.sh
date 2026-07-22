#!/bin/bash
# iac/check_gcp_setup.sh
# Verifies GCP setup for rails8-app-on-gcp

set -e

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
  echo "❌ No default project set in gcloud. Run: gcloud config set project <PROJECT_ID>"
  exit 1
fi

echo "🔍 Checking GCP setup for project: $PROJECT_ID"

echo "1️⃣ Checking ActiveStorage GCS Buckets..."
for env in dev test prod; do
  BUCKET_NAME="${PROJECT_ID}-activestorage-${env}"
  if gcloud storage ls "gs://${BUCKET_NAME}" &>/dev/null; then
    echo "✅ Bucket gs://${BUCKET_NAME} exists."
    # Count media. We suppress errors and count lines.
    COUNT=$(gcloud storage ls "gs://${BUCKET_NAME}/**" 2>/dev/null | wc -l | tr -d ' ')
    echo "   📊 Media in $env: $COUNT"
  else
    echo "❌ Bucket gs://${BUCKET_NAME} DOES NOT exist or access denied!"
  fi
done

echo "2️⃣ Checking Cloud Run Service Account..."
SA_EMAIL="rails-cloudrun-sa@${PROJECT_ID}.iam.gserviceaccount.com"
if gcloud iam service-accounts describe "$SA_EMAIL" &>/dev/null; then
  echo "✅ Service Account $SA_EMAIL exists."
else
  echo "❌ Service Account $SA_EMAIL DOES NOT exist!"
fi

echo "3️⃣ Checking Secret Manager for RAILS_MASTER_KEY..."
if gcloud secrets describe "rails-master-key" &>/dev/null; then
  echo "✅ Secret 'rails-master-key' exists."
else
  echo "❌ Secret 'rails-master-key' DOES NOT exist!"
fi

echo "🎉 GCP Verification complete."
