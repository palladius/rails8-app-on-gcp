# Workshop Skeleton

This is how the workshop is gonna look, high level:

1. **`workshop_1_local_baseline` (Install and Setup)**
   - The basic Rails 8 blog app running locally (SQLite + local disk ActiveStorage).
   - *Action*: Run `terraform apply` to start provisioning infrastructure in the background (especially Cloud SQL, which takes ~15 mins).

2. **`workshop_2_cloud_storage`**
   - ActiveStorage transition while waiting for SQL. Modify `config/storage.yml` and `production.rb` to use Google Cloud Storage.
   - Students create a *new* post to see the image successfully hit the bucket (the "remote storage thingy").

3. **`workshop_3_cloud_sql`**
   - Introducing the database! Cloud SQL should be finished provisioning by now. 
   - Connect the local Rails app to the Cloud SQL instance (using the Auth Proxy).

4. **`workshop_4_cloud_run_classic`**
   - Taking it live. Deploying the application to Cloud Run via the CLI (manual deployment without CI/CD).

5. **`workshop_5_cloud_build_cicd`**
   - Automating the deployment. Adding `cloudbuild.yaml` and setting up the CI/CD trigger to deploy to Cloud Run automatically on `git push`.

6. **`workshop_6_ai_features`** (Optional / Stretch)
   - Integrating a Gemini API feature, like the AI summarizing the post or tagging it automatically.

*Note: Sections 2 and 3 are intentionally ordered this way to keep students active while Cloud SQL provisions in the background.*