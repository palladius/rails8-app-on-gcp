# Step 4: Secret Manager

Never store plain-text passwords or secret keys in source control or `.env` files. We use **Google Cloud Secret Manager** to securely manage credentials.

1. Checkout the next branch:
   ```bash
   git checkout workshop_4_secret_manager
   ```

2. Store your Rails master key and database password in Secret Manager:
   ```bash
   gcloud secrets create rails-master-key --data-file=config/master.key
   gcloud secrets create rails-db-password --data-file=<(echo -n "$DB_PASSWORD")
   ```

3. Verify secret storage and retrieval directly from the CLI:
   ```bash
   gcloud secrets versions access latest --secret=rails-master-key
   ```

4. Grant your Cloud Run service account permission to access the secrets:
   ```bash
   gcloud secrets add-iam-policy-binding rails-master-key \
     --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
     --role="roles/secretmanager.secretAccessor"

   gcloud secrets add-iam-policy-binding rails-db-password \
     --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
     --role="roles/secretmanager.secretAccessor"
   ```

✨ **The Wow Moment:** You can safely delete local `.env` and credential files; Cloud Run will automatically fetch and inject these secrets into your container environment at runtime.

