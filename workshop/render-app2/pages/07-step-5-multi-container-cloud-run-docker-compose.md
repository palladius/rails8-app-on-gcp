# Step 5: Multi-Container Cloud Run & Docker Compose

In modern Rails 8 applications, background jobs are processed by **Solid Queue**. In production, we separate web traffic from background workers and attach the Cloud SQL Proxy as a sidecar container.

1. Checkout the next branch:
   ```bash
   git checkout workshop_5_cloud_run_classic
   ```

2. Inspect `compose.prod.yaml`:
   - **`web`**: Serves HTTP requests on port 8080.
   - **`worker`**: Runs Solid Queue (`bundle exec rails solid_queue:start`).
   - **`cloudsql-proxy`**: Official proxy sidecar container (`gcr.io/cloud-sql-connectors/cloud-sql-proxy:2`) bound to `5432`.

3. Test the multi-container stack locally:
   ```bash
   docker compose -f compose.prod.yaml up
   ```

4. Deploy the multi-container service to Cloud Run:
   ```bash
   gcloud run deploy rails-blog \
     --source . \
     --region us-central1 \
     --allow-unauthenticated \
     --set-secrets="RAILS_MASTER_KEY=rails-master-key:latest,DB_PASSWORD=rails-db-password:latest"
   ```

✨ **The Wow Moment:** The entire 3-container production stack (Web + Background Worker + Cloud SQL Proxy sidecar) boots locally with one Docker Compose command and deploys live to Cloud Run with zero architectural drift!

