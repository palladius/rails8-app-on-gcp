# Implementation Plan: CI/CD Pipelines for Cloud Run

## Phase 1: CI/CD Setup for Cloud Build
- [x] Task: Create `cloudbuild.yaml` in the repository root.
- [x] Task: Configure the build step to build the Docker image.
- [x] Task: Configure the push step to tag and push to Artifact Registry with commit SHA, semver tag (from VERSION file), and latest.
- [x] Task: Configure the deploy step for PRs to target isolated Cloud Run services (e.g. `palladius-genai-rails-app-pr-sha`).
- [x] Task: Configure the deploy step for `main` to target the `DEV` Cloud Run service.
- [ ] Task: Conductor - User Manual Verification 'CI/CD Setup for Cloud Build' (Protocol in workflow.md)

## Phase 2: CI/CD Setup for GitHub Actions
- [ ] Task: Create `.github/workflows/deploy.yml`.
- [ ] Task: Configure Workload Identity Federation authentication in the workflow.
- [ ] Task: Configure build, tag, and push steps to Artifact Registry (matching the Cloud Build logic).
- [ ] Task: Configure deployment rules based on branch triggers (PRs vs `main`).
- [ ] Task: Conductor - User Manual Verification 'CI/CD Setup for GitHub Actions' (Protocol in workflow.md)

## Phase 3: Workshop Documentation
- [ ] Task: Add a new markdown file `workshop/bonus-cicd-setup.md` detailing the CI/CD pipeline setup.
- [ ] Task: Explain the trade-offs between Cloud Build and GitHub Actions.
- [ ] Task: Provide step-by-step instructions for students to configure these triggers on their forks.
- [ ] Task: Conductor - User Manual Verification 'Workshop Documentation' (Protocol in workflow.md)
