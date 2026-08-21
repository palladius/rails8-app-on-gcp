# Step 3: Cloud SQL

Check your Terraform output in the other terminal. If it's finished, you now have a fully managed PostgreSQL database!

Let's switch our application from SQLite to Cloud SQL.

1. Checkout the next branch:
   ```bash
   git checkout workshop_3_cloud_sql
   ```
2. We need to connect to our new Cloud SQL instance. In production, Cloud Run handles this natively. Locally, we will use the **Cloud SQL Auth Proxy** to securely connect to our database.
3. Open `config/database.yml`. Notice how the `production` block is now configured to use the `postgresql` adapter and expects a `DATABASE_URL` environment variable.

