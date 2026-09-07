# Implementation Plan: Local Docker Compose Setup

## Phase 1: Docker Compose Definition
- [x] Task: Create `docker-compose.yml` with `db`, `pgadmin`, `mail`, `jobs`, `gcs` services. [c5fa85d]

## Phase 2: Rails Configuration
- [ ] Task: Update `config/storage.yml` to define a local GCS service pointing to port 4443.
- [ ] Task: Update `config/environments/development.rb` to route SMTP to port 1025.

## Phase 3: Verification
- [ ] Task: Run `docker-compose up -d`.
- [ ] Task: Verify web UI endpoints (pgAdmin, Mailpit).
- [ ] Task: Verify Rails ActiveStorage configuration.
