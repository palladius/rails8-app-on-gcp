# 💳 Google Cloud Billing, IAM & Authentication Troubleshooting

This guide covers real-world failure modes related to short-term workshop billing credits, Cloud SQL suspension, and Application Default Credentials (ADC).

---

## 🔴 `BillingNotEnabled` or `INACTIVE or ACCESS DENIED`

### Symptom
`just workshop-test` reports billing disabled, or `terraform apply` fails immediately with:
`Error 403: Google Cloud Billing API has not been used in project ... or it is disabled.`

### Cause
`cloudbilling.googleapis.com` is not enabled on newly created projects, preventing `bin/workshop_diagnostics.rb` and Terraform from querying status, or the project has not been linked to a billing account.

### Fix
```bash
# 1. Enable the Cloud Billing API
gcloud services enable cloudbilling.googleapis.com --project=$GOOGLE_CLOUD_PROJECT

# 2. Link your active billing account or workshop credit account
gcloud beta billing projects link $GOOGLE_CLOUD_PROJECT --billing-account=YOUR_ACCOUNT_ID
```

---

## 🔴 Cloud SQL Enters `SUSPENDED` (`BILLING_ISSUE`)

### Symptom
- `terraform apply` fails with:
  `Error when reading or editing SQL User "rails_user": googleapi: Error 400: Invalid request: Invalid request since instance is not running.`
- `gcloud sql instances restart` fails with:
  `HTTPError 409: Instance is not accessible to user. Instance state: SUSPENDED.`
- `gcloud sql instances describe` displays:
  ```yaml
  state: SUSPENDED
  suspensionReason:
  - BILLING_ISSUE
  ```

### Cause
When a short-term workshop coupon or billing account runs out of credit or reaches its validity limit (`OPEN: False`), Google Cloud immediately suspends active Cloud SQL instances to prevent overage charges.

### Fix & Recovery Procedure
1. Claim a new billing account or coupon (e.g. afternoon workshop credit).
2. Relink the project to the new open Billing Account ID:
   ```bash
   gcloud billing projects link $GOOGLE_CLOUD_PROJECT --billing-account=NEW_BILLING_ACCOUNT_ID
   ```
3. ⏳ **Crucial Waiting Window:** Cloud SQL runs an internal asynchronous billing sync loop. It takes **3 to 10 minutes** for Cloud SQL to clear `suspensionReason: BILLING_ISSUE`. Manual restart/patch requests will return 409 until the backend clears the flag.
4. Once cleared, Cloud SQL returns automatically to `state: RUNNABLE`, and `terraform apply` can resume safely.

---

## 🔴 ADC Missing or Mismatched with gcloud CLI

### Symptom
Terraform, Vertex AI Gemini, or Cloud TTS fails with authentication errors even though `gcloud auth login` succeeded.

### Cause
Google Cloud client libraries exclusively read credentials from Application Default Credentials (`~/.config/gcloud/application_default_credentials.json`), which is independent of the CLI user login.

### Fix
```bash
gcloud auth application-default login
```
