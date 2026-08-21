# Step 6: Automating with Cloud Build

Deploying from your laptop is great for testing, but in a real team, you want deployments to happen automatically when you push to GitHub.

1. Checkout the next branch:
   ```bash
   git checkout workshop_6_cloud_build_cicd
   ```
2. Take a look at the `cloudbuild.yaml` file. This file tells Google Cloud Build exactly how to build our Docker container, run our database migrations, and deploy to Cloud Run.
3. In the Google Cloud Console, we will set up a Cloud Build Trigger connected to our GitHub repository. 

Now, every time you `git push main`, your application will automatically build and deploy!

