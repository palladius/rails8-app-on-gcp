---
name: cloud-run-troubleshooting
description: Troubleshooting Cloud Run HTTP 500 errors and container crashes using Google Cloud Logging. Use whenever an application on Cloud Run returns HTTP 500, crashes on startup, or fails health checks.
---

# 🩺 Cloud Run Troubleshooting & Debugging Skill

When an application on Google Cloud Run returns an **HTTP 500 Internal Server Error**, fails TCP startup probes, or crashes unexpectedly, use the Google Cloud Logging CLI (`gcloud logging read`) to isolate the root cause immediately without navigating the web console.

---

## 🚀 Quick Diagnostic Recipe

### 1. View Container Crash & Startup Probe Failures
If the revision fails deployment or dies immediately:
```bash
gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.service_name="SERVICE_NAME" AND severity>=ERROR' \
  --project="PROJECT_ID" \
  --limit 15 \
  --format='table(timestamp,textPayload)'
```

### 2. View Real-Time HTTP 500 Exceptions & Stacktraces
Inspect recent application exceptions:
```bash
gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.service_name="SERVICE_NAME" AND (severity>=ERROR OR textPayload=~"500|Error|Exception|PG::")' \
  --project="PROJECT_ID" \
  --limit 20 \
  --format='table(timestamp,textPayload)'
```

### 3. Trace a Specific Request by ID
Rails logs every request with a unique UUID (`[<request-id>]`). When you see an error in the logs or in the HTTP headers (`x-request-id: <id>`):
```bash
gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.service_name="SERVICE_NAME" AND textPayload=~"REQUEST_ID"' \
  --project="PROJECT_ID" \
  --limit 30 \
  --format='table(timestamp,textPayload)'
```

---

## 🎯 Common Root Causes on Cloud Run

| Symptom | Cloud Logging Diagnostic Signal | Typical Root Cause & Fix |
|---|---|---|
| **HTTP 500 on Signup / Background Jobs** | `relation "solid_queue_jobs" does not exist` | Multi-database queue migrations were not run. Ensure `bin/rails db:prepare:queue` runs in `docker-entrypoint`. |
| **HTTP 500 on Image Uploads** | `Invalid bucket name: '-activestorage-...'` | `GOOGLE_CLOUD_PROJECT` environment variable is not passed to the Cloud Run service, resulting in empty bucket prefix. |
| **Startup Probe Fails (Port 8080)** | `Default STARTUP TCP probe failed 1 time consecutively` | Rails boot failed inside `docker-entrypoint` (e.g. database uncontactable or missing credentials). Run logs with `limit 30` to see stderr. |
| **Missing Admin Warning Banner** | `Notice: No administrator user found in database!` | Container started without `GOOGLE_CLOUD_ACCOUNT` or `db:seed` was not triggered during entrypoint boot. |
