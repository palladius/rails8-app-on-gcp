# Stage 2: Google Cloud Storage Uplift & POLA Warning

### Purpose
In this stage:
- Database: Still local SQLite (ephemeral)
- Storage: Persistent Google Cloud Storage with private IAM signing (`iam: true`)
- Demonstrates persistence of media assets across container restarts while illustrating the POLA Warning (pending background jobs without worker container).

### Overlay Target Files
- `blog/config/database.yml`: SQLite
- `blog/config/storage.yml`: Google Cloud Storage (`iam: true`)
- `blog/config/environments/production.rb`: active_storage service `:google_prod`
