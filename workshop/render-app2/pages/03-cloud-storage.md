# 3. Google Cloud Storage

ActiveStorage makes it easy to handle file uploads. In production, we'll use Google Cloud Storage (GCS) as our backend.

## Configuration

In `config/storage.yml`:
```yaml
google:
  service: GCS
  project: <%= ENV.fetch("GOOGLE_CLOUD_PROJECT") %>
  credentials: <%= ENV.fetch("GOOGLE_APPLICATION_CREDENTIALS") %>
  bucket: <%= ENV.fetch("GCS_BUCKET") %>
```

We will set up a service account and bind it to our Cloud Run service later.
