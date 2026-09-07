# Specification: Local Docker Compose Setup (Issue #10)

## Overview
Create a robust `docker-compose.yml` for local development.

## Functional Requirements
- Must provide PostgreSQL 16 on port 5432.
- Must provide pgAdmin on port 5050.
- Must provide Mailpit on port 8025 (SMTP on 1025).
- Must provide `fake-gcs-server` on port 4443.
- Must include a `jobs` worker service for SolidQueue/Sidekiq.
- Development environment must be configured to point to Mailpit for ActionMailer.
- Development environment must be configured to point to `fake-gcs-server` for ActiveStorage.

## Out of Scope
- Running the Rails `web` app itself within the compose cluster (it runs via `bin/dev` on the host).
