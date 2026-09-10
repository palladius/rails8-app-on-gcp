# ☁️ Cloud Run Troubleshooting & Logging Recipes

When an application on Google Cloud Run returns an **HTTP 500 Internal Server Error**, fails TCP startup probes, or crashes unexpectedly, use Google Cloud Logging CLI (`gcloud logging read`) to isolate the root cause immediately without navigating the web console.

---

## 🚀 Quick Diagnostic Recipes

### 1. View Container Crash & Startup Probe Failures
If the revision fails deployment or dies immediately during boot:
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
Rails logs every request with a unique UUID (`[<request-id>]`). When you see an error in the response headers (`x-request-id: <id>`):
```bash
gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.service_name="SERVICE_NAME" AND textPayload=~"REQUEST_ID"' \
  --project="PROJECT_ID" \
  --limit 30 \
  --format='table(timestamp,textPayload)'
```

---

## 🎯 Common Cloud Run Failure Modes

### 🔴 Startup Probe Fails on Port 8080
- **Signal:** `Default STARTUP TCP probe failed 1 time consecutively for container "puma" on port 8080.`
- **Cause:** Rails failed to boot inside `bin/docker-entrypoint` before Puma could bind to port 8080 (e.g. database migration error, syntax error, or uncontactable database).
- **Fix:** Fetch stdout/stderr logs with `--limit 50` to inspect entrypoint failure output:
  ```bash
  gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.service_name="blog"' --limit 50
  ```

### 🔴 Multi-Container Dependency Race Condition
- **Signal:** Puma container crashes on startup because Cloud SQL Auth Proxy sidecar container is not yet accepting connections on `127.0.0.1:5432`.
- **Cause:** In Cloud Run multi-container setups, containers start concurrently unless explicit dependency startup ordering or connection retry loops are configured.
- **Fix:** Ensure Rails database connection has pool timeouts and reconnect retries configured in `blog/config/database.yml`.
