# 2. Local Setup

Before deploying to the cloud, it's crucial to have a functional local environment.

## The Local Stack
- Ruby 3.4
- Rails 8
- SQLite (for simple local dev) or PostgreSQL via docker-compose
- Solid Queue & Solid Cache

## Getting Started
```bash
git clone https://github.com/palladius/rails8-app-on-gcp
cd rails8-app-on-gcp
just setup
just test
```
