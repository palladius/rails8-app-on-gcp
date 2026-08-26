# Step 6: Automating with Cloud Build (Optional / Skippable)

> 💡 **Note:** If you want to jump straight to building AI features, you can skip this step and proceed to Step 7!

Manual deployments from a developer laptop are error-prone. Let's automate the deployment with **Cloud Build**.

1. Checkout the next branch:
   ```bash
   git checkout workshop_6_cloud_build_cicd
   ```

2. Inspect `cloudbuild.yaml`. It defines 3 automated pipeline steps:
   - **Build**: Compiles the production Docker image.
   - **Migrate**: Runs `rails db:migrate` using a transient Cloud Run Job.
   - **Deploy**: Updates the Cloud Run service with the newly built container image.

3. Connect your GitHub repository to Cloud Build using the GCP Console Triggers page.

✨ **The Wow Moment:** Every `git push` to `main` triggers a fully automated build, test, migration, and deployment in Google Cloud!

