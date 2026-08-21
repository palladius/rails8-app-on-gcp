# 6. CI/CD Pipelines

To automate deployments, we use Cloud Build.

Every push to the `main` branch will:
1. Run RSpec tests.
2. Build the Docker image.
3. Apply database migrations.
4. Deploy the new version to Cloud Run.
