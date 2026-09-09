# 💥 What Could Possibly Go Wrong? (And How to Fix It)

A catalog of real-world failure modes, gotchas, and troubleshooting recipes encountered during workshop development, Friction Logs (FL-001, FL-002, FL-003), and live Cloud Run deployments.

---

## 1. ☁️ Google Cloud & Billing Failures

### 🔴 `BillingNotEnabled` or `INACTIVE or ACCESS DENIED`
- **Symptom:** `just workshop-test` reports billing disabled, or Terraform fails immediately with `BillingNotEnabled`.
- **Cause:** `cloudbilling.googleapis.com` is not enabled on new projects, preventing `bin/workshop_diagnostics.rb` from querying status, or the project has not been linked to a billing account.
- **Fix:**
  ```bash
  gcloud services enable cloudbilling.googleapis.com --project=$GOOGLE_CLOUD_PROJECT
  gcloud beta billing projects link $GOOGLE_CLOUD_PROJECT --billing-account=YOUR_ACCOUNT_ID
  ```

### 🔴 ADC Missing or Mismatched with gcloud CLI
- **Symptom:** Terraform, Vertex AI Gemini, or Cloud TTS fails with authentication errors even though `gcloud auth login` succeeded.
- **Cause:** Google client libraries exclusively read `~/.config/gcloud/application_default_credentials.json`.
- **Fix:**
  ```bash
  gcloud auth application-default login
  ```

---

## 2. 🐘 Database & Cloud Run Startup Failures

### 🔴 `relation "solid_queue_jobs" does not exist` (HTTP 500 on Signup / Mailers)
- **Symptom:** Opening `/session/new` or registering a user returns HTTP 500.
- **Cause:** Rails 8 uses multi-database configuration where queue tables live in `db/queue_schema.rb`. The default `db:prepare` only migrates the primary database.
- **Fix:** Ensure `blog/bin/docker-entrypoint` prepares all databases:
  ```bash
  ./bin/rails db:prepare
  ./bin/rails db:prepare:queue || true
  ./bin/rails db:prepare:cache || true
  ./bin/rails db:prepare:cable || true
  ```

### 🔴 `Notice: No administrator user found in database!`
- **Symptom:** Red educational warning banner appears on the blog homepage after deploy.
- **Cause:** Cloud Run container started without `GOOGLE_CLOUD_ACCOUNT` / `ADMIN_EMAIL`, or `docker-entrypoint` did not execute `bin/rails db:seed`.
- **Fix:** Pass admin credentials via `--set-env-vars GOOGLE_CLOUD_ACCOUNT="user@gmail.com",APP_ADMIN_PASSWORD="..."` and ensure `docker-entrypoint` calls `db:seed`.

---

## 3. 🪣 Storage & ActiveStorage Failures

### 🔴 `Invalid bucket name: '-activestorage-prod'`
- **Symptom:** Container crashes during boot with `Google::Apis::ClientError: invalid: Invalid bucket name`.
- **Cause:** `blog/config/storage.yml` builds bucket name as `<%= gcp_project %>-activestorage-prod`. If `GOOGLE_CLOUD_PROJECT` is not in the container environment, `gcp_project` evaluates to empty string `""`.
- **Fix:** Always pass `GOOGLE_CLOUD_PROJECT` in Cloud Run deploy:
  ```bash
  --set-env-vars GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT
  ```

---

## 4. 🛠️ Development & Tooling Friction

### 🔴 `Bundler::GemNotFound` during `just workshop-uat` in Git Worktree
- **Symptom:** `just workshop-uat 2` fails with missing gems when run inside a secondary git worktree.
- **Cause:** Git worktrees do not share `.bundle/` and `vendor/bundle/` from the main repository.
- **Fix:** Copy `blog/.bundle` and `blog/vendor/bundle` from the main repo root into the worktree.
