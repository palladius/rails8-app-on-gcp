# Initial Concept
A golden Rails App optimized for GCP (ActiveStorage on GCS, docker-compose on Cloud Run) to show Rubyists how to seamlessly deploy Rails 8 on Google Cloud.

## Target Audience
- **Primary:** Workshop Attendees (Developers learning how to deploy Rails 8 on GCP).
- **Secondary:** Ruby developers looking for a repeatable blueprint/starter kit for GCP deployments.

## Primary Goal
The primary business reason is to serve as an educational hands-on lab environment for a workshop. The application MUST be fully functional from Day 0 locally. Then, the workshop will guide attendees through migrating it to GCP, pointing local environments to production databases to verify setup before final deployment to Cloud Run.

It also acts as a production-ready boilerplate and a showcase for Rails 8 capabilities (Solid Queue, Solid Cache, Action Cable) running on Cloud Run.

## Workshop Documentation Strategy
We will build a multi-page workshop incrementally in the `workshop/` directory alongside the application. This ensures we capture all the minutiae, friction logs, and design decisions (e.g., why docker-compose is set up this way, why ActiveStorage is configured that way) while they are fresh.

## Key Features & Roadmap
### v1 (Fundamental for Workshop Start)
- **Local Day 0 Experience:** App is fully functional using local SQLite and local storage.
- **Google Cloud Storage (GCS) Integration:** Native ActiveStorage support for file uploads.
- **Cloud Run Deployment:** Containerized execution with proper workflows. 
- **Local-to-Prod Verification:** Ensure `RAILS_ENV=production` works locally connected to the Cloud SQL DB to iron out master keys, hostnames, and IP issues before deploying to Cloud Run.

### v2 (Securization & Scaling Add-ons)
- **Secret Manager Integration:** Secure handling of credentials and environment variables.
- **Cloud SQL (PostgreSQL):** Robust relational database for primary data and Solid components.
