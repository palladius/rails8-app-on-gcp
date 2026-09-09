# Conductor Track Specification: Diagnostics Suite (`just workshop-test`)

> **Track ID:** `diagnostics_suite_issue_24_20260907`  
> **Type:** Feature  
> **Related Issue:** [#24 (Child of #2)](https://github.com/palladius/rails8-app-on-gcp/issues/24)  

---

## 🎯 Overview & Strategic Value
Before executing any infrastructure command (`terraform apply`) or deploying to Google Cloud Run, students need an immediate, automated sanity check. 
The **Diagnostics Suite (`just workshop-test`)** prevents blind execution and frustating errors by verifying:
1. **User Identity & Admin Email**: Validates `ADMIN_EMAIL` in `.env`. Throws an error if missing; gives a warning if it's not a `@gmail.com` or `@google.com` address.
2. **GCP Project & Billing Enabled**: Verifies that `GOOGLE_CLOUD_PROJECT` is set, `gcloud` is logged in, and **GCP Billing is linked and active** via `gcloud beta billing projects describe`. Without billing, Terraform and Cloud SQL fail immediately.
3. **Application Default Credentials (ADC)**: Validates that `gcloud auth application-default print-access-token` works (needed for Vertex AI GenAI calls).
4. **Rails Secrets**: Verifies `config/master.key` on disk or `RAILS_MASTER_KEY` in environment.
5. **GCS & Canary Check**: Checks GCS bucket connectivity and verifies if the canary seed image (`seeds/gcs_dev_image.jpg`) is present.
6. **Telemetry & Visual Badge**: Stampa visivamente lo stato architetturale: `[🪫🪣 S0]`, `[🪫🪣 S1]`, `[🪫☁️ S2]`, o `[🔋☁️ S3]`.

---

## 📋 Functional Requirements
- Executable via `just workshop-test` from repository root.
- Colorful, clear CLI output featuring emojis (🦖, ✅, ⚠️, ❌, 🐤, 🧭).
- Non-zero exit code on blocking errors (e.g. missing admin email, billing not enabled, no gcloud account).
- Zero exit code when ready or with non-blocking warnings.
