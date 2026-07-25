# Specification: CI/CD Pipelines for Cloud Run (Cloud Build & GitHub Actions)

## Overview
Implement robust CI/CD pipelines to build, version, and deploy the Rails 8 application to Google Cloud Run. To evaluate the best developer experience, we will configure and document both **Google Cloud Build** and **GitHub Actions**. This pipeline will automate testing, versioning (Artifact Registry), and multi-environment deployment (Ephemeral PRs, DEV, PROD).

## Functional Requirements
1. **Dual CI/CD Implementation:**
   - Create workflows/triggers for both Google Cloud Build (`cloudbuild.yaml`) and GitHub Actions (`.github/workflows/`).
   - Use Workload Identity Federation (or similar secure auth) for GitHub Actions to authenticate with GCP.
2. **Pull Request Workflow (Targeting `main`):**
   - Trigger: Opened, Synchronize, Reopened.
   - Build the Docker image and push to Artifact Registry (tagged with the commit SHA).
   - Deploy to an isolated, ephemeral Cloud Run service named dynamically (e.g., `palladius-genai-rails-app-pr-123`).
   - (Note: Teardown logic for these ephemeral environments when the PR is closed/merged will be handled, or at least documented as a follow-up concern).
3. **Main Branch Workflow (Pushes to `main`):**
   - Trigger: Push to `main`.
   - Build the Docker image and push to Artifact Registry.
   - Tag the image with the semantic version (e.g., `v1.2.3`) parsed from the `VERSION` file, as well as `latest`.
   - Deploy the new image to the **DEV** Cloud Run service.
   - Run integration tests against the DEV service.
   - If tests pass, promote and deploy the image to the **PROD** Cloud Run service.
4. **Workshop Documentation:**
   - Add an optional, advanced "Bonus" section in the workshop documentation.
   - This section will explain to "clever" students how to set up the CI/CD triggers on their own forks, discussing the trade-offs between Cloud Build and GitHub Actions.

## Out of Scope
- Automatic cleanup of ephemeral PR Cloud Run services (to be addressed in a subsequent track).
- Complete migration of students away from manual CLI deployment (this remains an optional bonus).
