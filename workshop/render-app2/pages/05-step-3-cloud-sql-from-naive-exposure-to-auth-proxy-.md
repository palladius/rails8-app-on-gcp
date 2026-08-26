# Step 3: Cloud SQL (From Naive Exposure to Auth Proxy)

Check your terminal: by now, your Cloud SQL PostgreSQL instance has finished provisioning!

Let's switch our application from SQLite to Cloud SQL.

1. Checkout the next branch:
   ```bash
   git checkout workshop_3_cloud_sql
   ```

### Phase 3A: The Naive Connection (The `0.0.0.0/0` Anti-Pattern)

To demonstrate how traditional setups connected to databases, let's create a database user and open the firewall:

1. Create the database and user:
   ```bash
   gcloud sql databases create rails_production --instance=$CLOUDSQL_INSTANCE_NAME
   gcloud sql users create rails_user --instance=$CLOUDSQL_INSTANCE_NAME --password=$DB_PASSWORD
   ```

2. Add an authorized network rule for `0.0.0.0/0`:
   ```bash
   gcloud sql instances patch $CLOUDSQL_INSTANCE_NAME --authorized-networks=0.0.0.0/0
   ```

3. Test direct public connection:
   ```bash
   psql -h $CLOUDSQL_PUBLIC_IP -U rails_user -d rails_production
   ```

> ⚠️ **CAUTION: The Security Anti-Pattern.**  
> Exposing port `5432` to `0.0.0.0/0` on the public internet exposes your database to brute-force attacks, port scanning bots, and catastrophic leaks. We did this only to prove connectivity—now we immediately lock it down!

### Phase 3B: The Secure Solution — Cloud SQL Auth Proxy

Let's remove the public network authorization and connect through the secure **Cloud SQL Auth Proxy**:

1. Remove `0.0.0.0/0` from authorized networks:
   ```bash
   gcloud sql instances patch $CLOUDSQL_INSTANCE_NAME --clear-authorized-networks
   ```

2. Start the Cloud SQL Auth Proxy locally on port 5432:
   ```bash
   cloud-sql-proxy --port 5432 $CLOUDSQL_INSTANCE_CONNECTION_NAME
   ```

3. In another terminal, run your database migrations and seed through the secure local proxy:
   ```bash
   DATABASE_URL=postgresql://rails_user:${DB_PASSWORD}@127.0.0.1:5432/rails_production bin/rails db:migrate db:seed
   ```

4. Start your Rails server:
   ```bash
   DATABASE_URL=postgresql://rails_user:${DB_PASSWORD}@127.0.0.1:5432/rails_production bin/rails s
   ```

✨ **The Wow Moment:** Refresh `http://localhost:3000`! You will see a newly seeded welcome article: *"🐘 Welcome to Cloud SQL!"* loaded live from your managed PostgreSQL instance in the cloud via the secure IAM proxy tunnel without any open public firewall ports!

