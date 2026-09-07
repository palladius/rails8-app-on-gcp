# Workshop

* **Title**: Deploying Modern [Rails 8](https://rubyonrails.org/) Applications to Google Cloud: From Zero to AI
* **Abstract**: Take a modern [Rails 8](https://rubyonrails.org/) monolith from local dev to a resilient, serverless production architecture on Google Cloud with Google Antigravity. Master multi-container Cloud Run deployments, zero-trust security, private cloud storage, and background GenAI pipelines.

## About

In this workshop, you will learn to deploy a modern, sophisticated application to Google Cloud:

* 🔵 **Multi-Container [Cloud Run with Docker Compose](https://docs.cloud.google.com/run/docs/deploy-run-compose)**: Run [Rails 8](https://rubyonrails.org/), background [Solid Queue](https://github.com/rails/solid_queue) workers, and proxy sidecars together without Kubernetes complexity.
* 🔴 **Zero-Trust Access with [Identity-Aware Proxy (IAP)](https://cloud.google.com/security/products/iap)**: Protect your app at the load balancer with Google IAM—no custom auth code required.
* 🟡 **Secure Database Access with Secret Manager**: Connect to [Cloud SQL](https://cloud.google.com/sql) PostgreSQL over encrypted mTLS while avoiding insecure allow-all database networks.
* 🟢 **Private Asset Storage with IAM Signing**: Store uploads in private Google Cloud Storage buckets using [short-lived signed URLs](https://cloud.google.com/storage/docs/access-control/signed-urls)—no world-readable buckets.
* 🔵 **Async GenAI with Gemini & [Solid Queue](https://github.com/rails/solid_queue)**: Generate AI blog covers via Google Imagen 3 using Rails 8 native database-backed queues.
* 🔴 **AI Pair Programming with Google Antigravity**: Speed up troubleshooting, coding, and cloud deployments with intelligent pair programming.
