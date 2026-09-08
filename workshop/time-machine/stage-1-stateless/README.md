# Stage 1: The Stateless Shock (Single Container SQLite)

### Purpose
In this stage, the application is configured for a single stateless Cloud Run container deployment:
- Database: Local SQLite on container disk (`storage/production.sqlite3`)
- Storage: Local Disk storage on container disk (`storage/`)
- Demonstrates the **Stateless Shock**: when the Cloud Run container restarts or scales to 0, all uploaded images and database records evaporate!

### Overlay Target Files
- `blog/config/database.yml`: pure SQLite
- `blog/config/storage.yml`: pure Disk service
- `blog/config/environments/production.rb`: active_storage service `:local`
