# rails8-app-on-gcp

A golden Rails App optimized for GCP (ActiveStorage on GCS, docker-compose on Cloud Run, ...)

## Development

We use `just` to orchestrate common tasks. To get started easily:

```bash
# Installs dependencies and prepares the database
just install

# Boots up the local development server
just dev
```

If you don't have `just` installed, you can simply change into the `blog/` directory and use standard Rails commands:

```bash
cd blog/
bundle install
bin/rails db:prepare
bin/dev -p 9090
```
