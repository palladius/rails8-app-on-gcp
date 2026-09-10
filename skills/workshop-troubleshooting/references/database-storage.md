# 🐘 Database & Storage Failure Modes

This guide catalogs persistence errors, migration bugs, and ActiveStorage issues encountered in Rails 8 on Google Cloud.

---

## 🔴 `relation "solid_queue_jobs" does not exist` (HTTP 500 on Signup / Jobs)

### Symptom
Opening `/session/new`, registering a user, or triggering a mailer returns HTTP 500.

### Cause
Rails 8 uses a multi-database architecture where Solid Queue tables live in `db/queue_schema.rb`. The default `bin/rails db:prepare` only migrates the primary application database (`db/schema.rb`).

### Fix
Ensure all multi-database schema migrations are executed (e.g. inside `blog/bin/docker-entrypoint`):
```bash
./bin/rails db:prepare
./bin/rails db:prepare:queue || true
./bin/rails db:prepare:cache || true
./bin/rails db:prepare:cable || true
```

---

## 🔴 `Invalid bucket name: '-activestorage-prod'`

### Symptom
Container crashes during startup with:
`Google::Apis::ClientError: invalid: Invalid bucket name: '-activestorage-prod'`

### Cause
`blog/config/storage.yml` constructs the bucket name dynamically:
```yaml
bucket: <%= ENV['GOOGLE_CLOUD_PROJECT'] %>-activestorage-prod
```
If `GOOGLE_CLOUD_PROJECT` is not passed as an environment variable to the Cloud Run service, the expression evaluates to `""-activestorage-prod`.

### Fix
Always include `GOOGLE_CLOUD_PROJECT` when deploying or updating Cloud Run services:
```bash
gcloud run services update blog --set-env-vars GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT
```

---

## 🔴 `Notice: No administrator user found in database!`

### Symptom
A red educational warning banner appears across the blog homepage after deploying to Cloud Run.

### Cause
The database was created, but no admin user exists because `bin/rails db:seed` did not run, or `GOOGLE_CLOUD_ACCOUNT` was missing at seed time.

### Fix
Pass admin email and password in Cloud Run environment variables:
```bash
gcloud run services update blog \
  --set-env-vars GOOGLE_CLOUD_ACCOUNT="student@example.com",APP_ADMIN_PASSWORD="SecurePassword123"
```
And execute database seeding:
```bash
gcloud run jobs execute db-seed # or via Cloud Run revision startup
```
