# Step 4: Secret Manager

Security is critical. We have a database password and a `RAILS_MASTER_KEY` (used to decrypt Rails credentials) that we cannot check into version control.

Instead of relying on fragile `.env` files in production, we will use **Google Cloud Secret Manager**.

1. Checkout the next branch:
   ```bash
   git checkout workshop_4_secret_manager
   ```
2. Our Terraform script created two empty secrets: `rails-master-key` and `rails-db-password`.
3. Let's populate them! Use the `gcloud` CLI to add your actual `master.key` content to Secret Manager:

```bash
gcloud secrets versions add rails-master-key --data-file=config/master.key
```

Now, when we deploy our app, Cloud Run will automatically fetch this secret and inject it into our container as an environment variable!

