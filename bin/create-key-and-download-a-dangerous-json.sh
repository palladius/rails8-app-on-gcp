#!/bin/bash
# bin/create-key-and-download-a-dangerous-json.sh

set -e

echo "⚠️  WARNING: THIS IS DANGEROUS AND NOT RECOMMENDED! ⚠️"
echo "Creating and downloading Service Account JSON keys poses a significant security risk."
echo "Use ADC (Application Default Credentials) whenever possible."
echo "----------------------------------------------------------------------------------"

PROJECT_ID=$(grep '^GOOGLE_CLOUD_PROJECT=' ../.env | cut -d '"' -f 2)
KEY_PATH="private/${PROJECT_ID}-key.json"
SA_NAME="workshop-tf-runner"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

if [ -f "$KEY_PATH" ]; then
  echo "oh i see u already have the key, skipping"
  exit 0
fi

echo "Ensure we are using the correct identity..."
gcloud config set account palladiusbonton@gmail.com

echo "Creating Service Account '$SA_NAME' in project '$PROJECT_ID'..."
gcloud iam service-accounts create "$SA_NAME" \
    --display-name="Terraform Runner for Workshop" \
    --project="$PROJECT_ID" || echo "Service account may already exist, proceeding..."

echo "Granting Owner role to the Service Account..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/owner" \
    --condition=None

echo "Downloading the JSON key to $KEY_PATH..."
mkdir -p private
gcloud iam service-accounts keys create "$KEY_PATH" \
    --iam-account="$SA_EMAIL" \
    --project="$PROJECT_ID"

echo "✅ Success! The dangerous JSON key has been securely stored in $KEY_PATH."
