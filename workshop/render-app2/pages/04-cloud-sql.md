# 4. Cloud SQL

SQLite is great for development, but for production, we need a robust relational database.

## Provisioning

We use a fully managed PostgreSQL instance on Cloud SQL.

- **VPC Peering:** Allows Cloud Run to connect securely via private IP.
- **Connection pooling:** Configure Rails database.yml to handle connection limits properly.
