# Step 5: Cloud Run Deployment

It's time to take our blog live! We will deploy the application to Google Cloud Run, a fully managed serverless platform.

1. Checkout the next branch:
   ```bash
   git checkout workshop_5_cloud_run_classic
   ```
2. We will use the `gcloud run deploy` command to build our container and deploy it in one step. 

```bash
gcloud run deploy rails-blog \
  --source . \
  --region us-central1 \
  --allow-unauthenticated \
  --set-secrets="RAILS_MASTER_KEY=rails-master-key:latest"
```

Once the deployment finishes, click the URL provided in the terminal. Your Rails 8 blog is now live on the internet, backed by Cloud SQL and Cloud Storage!

