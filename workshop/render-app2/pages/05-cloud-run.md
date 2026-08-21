# 5. Cloud Run

Cloud Run is Google's fully managed serverless container platform.

## Dockerizing Rails 8

Rails 8 comes with a great default `Dockerfile`. We simply build the container and deploy it to Cloud Run.

```bash
gcloud run deploy rails-app \
  --source . \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars="RAILS_ENV=production"
```
