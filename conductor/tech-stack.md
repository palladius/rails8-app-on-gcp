# Technology Stack

## Core Technologies
- **Programming Language:** Ruby 3.4
- **Backend Framework:** Ruby on Rails 8.1
- **Database (Development):** SQLite
- **Database (Production):** PostgreSQL (via Google Cloud SQL)

## Frontend
- **Framework:** Hotwire (Turbo & Stimulus) - Rails defaults
- **Styling:** Standard CSS (with Googley/Gemini aesthetic, minimal external dependencies)

## Infrastructure & Orchestration (GCP)
- **Deployment Platform:** Google Cloud Run (Containerized via Docker)
- **File Storage:** Google Cloud Storage (via ActiveStorage)
- **Background Jobs & Caching:** Solid Queue, Solid Cache, and Solid Cable (using the DB backend)
- **Secrets Management:** Google Secret Manager (planned for v2)
- **Task Runner:** `just` (via justfile)
