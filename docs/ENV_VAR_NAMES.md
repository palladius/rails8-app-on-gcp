# 🌐 Environment Variable Names & Standardization (`docs/ENV_VAR_NAMES.md`)

> **Constitutional Authority:** This specification formalizes the canonical environment variable naming convention for **`rails8-app-on-gcp`**.
> It defines the approved variables, why they were chosen, and strictly prohibits non-standard or legacy variable names (e.g. `GCP_*`).

---

## 🧭 Principles & Naming Rationale

1. **Google Cloud Standard (`GOOGLE_CLOUD_*`):**
   - Official Google Cloud SDKs, Cloud Run runtimes, Application Default Credentials (ADC), Terraform Google Provider, and Vertex AI libraries natively look for or expect variables prefixed with `GOOGLE_CLOUD_*` (or Google Cloud internal SDK variables like `CLOUDSDK_CORE_*`).
   - Using the ad-hoc shorthand `GCP_*` leads to configuration drift, duplicate mappings, and broken interoperability across official client libraries.
2. **Predictable Rails Defaults:**
   - Secrets and passwords follow Rails / Docker conventions (`APP_ADMIN_PASSWORD`, `DATABASE_URL`, `RAILS_MASTER_KEY`).
3. **Fail Fast & Loud:**
   - Pre-flight diagnostic tools (`bin/workshop_diagnostics.rb` / `just workshop-test`) fail with clear error messages if deprecated or non-standard variables are present in `.env`.

---

## ✅ Approved Canonical Environment Variables

| Variable Name | Purpose & Scope | Rationale / Canonical Standard |
| :--- | :--- | :--- |
| `GOOGLE_CLOUD_PROJECT` | Active Google Cloud Project ID | **The universal GCP standard.** Used by Vertex AI, Secret Manager, Cloud SQL client, Cloud Storage, and Terraform. Replaces deprecated `PROJECT_ID` and `GCP_PROJECT_ID`. |
| `GOOGLE_CLOUD_ACCOUNT` | Primary Google user identity (e.g., `user@gmail.com` or `user@google.com`) | Used for Google Cloud Billing checks, Terraform IAM policy bindings (`user:${email}`), ADC, and IAP identity. Automatically serves as the default administrator email for Rails `db:seed`. Replaces deprecated `GCLOUD_USER` and `GCP_EMAIL`. |
| `GOOGLE_CLOUD_REGION` | GCP deployment region (e.g. `us-central1`, `europe-west1`) | Official Google Cloud standard for regional services (Cloud Run, Cloud SQL, Vertex AI). Defaults to `europe-west1`, matching `iac/variables.tf`. Replaces `GCP_REGION`. |
| `GOOGLE_CLOUD_LOCATION` | Region/Location for AI and regional endpoints | Synonymous with or paired with `GOOGLE_CLOUD_REGION` for Vertex AI model locations. |
| `APP_ADMIN_PASSWORD` | Initial seeded password for the Rails blog administrator | Explicitly distinguishes application admin password from system or cloud database passwords. Defaults to `Ch4ng3m3!!1`. |
| `DATABASE_URL` | Connection string for PostgreSQL or SQLite | Rails standard 12-factor database URL. (e.g. `postgresql://user:pass@127.0.0.1:5432/blog_development`). |
| `CLOUDSQL_INSTANCE` | Cloud SQL instance connection name (`project:region:instance`) | Used by Cloud SQL Auth Proxy sidecar container on Cloud Run. |
| `ACTIVE_STORAGE_SERVICE` | Rails ActiveStorage service selector (`local`, `gcs_local`, `google`) | Controls whether ActiveStorage uploads to local disk or Google Cloud Storage. |
| `GCS_BUCKET_NAME` | Cloud Storage bucket name for ActiveStorage blobs | Storage bucket name for production and cloud-connected development. |
| `GCS_SIGNER_SA_EMAIL` | Service Account email for IAM blob URL signing | Used by `iam: true` in `config/storage.yml` when generating short-lived signed URLs via Cloud Run metadata server or local development. |
| `GEMINI_API_KEY` | Gemini AI Developer API key | Direct API key for Google AI Studio / Gemini API. If omitted, the app uses Vertex AI via ADC (`GOOGLE_CLOUD_PROJECT`). |
| `NANOBANANA_MODEL` | Gemini / Imagen model version string | Specifies which generative AI model to invoke (e.g., `gemini-2.5-flash`, `imagen-3.0-generate-002`). |
| `AUDIO_LANGUAGES` | Comma-separated languages for AI podcastifier (e.g. `it,en`) | Configures audio generation pipelines. |
| `IAP_ALLOWED_USERS` | Comma-separated allowlist of emails for Identity-Aware Proxy | Application-level Zero-Trust guard for Cloud Run IAP headers. |
| `RAILS8_ENV_LAUNCH_MODE` | Human-readable badge text override | Displayed in application footer and `/status` page to provide clear environment context. |
| `RAILS_MASTER_KEY` | Decryption key for Rails encrypted credentials | Standard Rails credential decryption key when `config/master.key` is not mounted. |

---

## 🚫 Denylist & Prohibited Legacy Variables

The following variables are **STRICTLY PROHIBITED**. The diagnostics test (`just workshop-test`) will abort with an error if any of these are found in `.env`:

| Prohibited Variable | Status | Replacement | Why it is banned |
| :--- | :--- | :--- | :--- |
| `GCP_PROJECT_ID` | ❌ **BANNED** | `GOOGLE_CLOUD_PROJECT` | Non-standard. Conflicts with official Google Cloud SDKs and Terraform variables. |
| `PROJECT_ID` | ❌ **BANNED** | `GOOGLE_CLOUD_PROJECT` | Ambiguous. Can collide with OS or CI project definitions. |
| `GCP_EMAIL` | ❌ **BANNED** | `GOOGLE_CLOUD_ACCOUNT` | Ambiguous whether it represents a human account or service account. |
| `GCLOUD_USER` | ❌ **BANNED** | `GOOGLE_CLOUD_ACCOUNT` | Legacy naming; conflicts with official IAM identity conventions. |
| `GCP_REGION` | ❌ **BANNED** | `GOOGLE_CLOUD_REGION` | Non-standard shorthand. |
| `GCP_*` | ❌ **BANNED** | `GOOGLE_CLOUD_*` | Any variable with prefix `GCP_` is deprecated across this repository. |

---

## 🧪 Verification & Enforcement

Whenever you add or modify environment variables:
1. Document the variable in `.env.dist` with explanatory comments.
2. Run `just workshop-test` to verify that anti-legacy guards validate cleanly.
3. Inspect `/status` to confirm telemetry safely displays the variable without leaking secrets.
