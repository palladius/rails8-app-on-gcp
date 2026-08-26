# Introduction

![Rails on Google Cloud](assets/images/rails_gcp_logo.jpg)

Welcome to the Rails 8 on Google Cloud workshop! In this hands-on codelab, you will take a modern Rails 8 application from a simple local SQLite setup to a fully scalable, secure, and AI-powered production application on Google Cloud.

We will explore best practices for deploying Rails 8, managing secrets, connecting securely to Cloud SQL via the **Cloud SQL Auth Proxy**, orchestrating multi-container services on Cloud Run with Docker Compose, and tapping into Google's Gemini models for generative AI features.

### What you'll learn
- How to provision Google Cloud infrastructure asynchronously using Terraform or CLI scripts.
- How to transition from local disk storage to private Google Cloud Storage with IAM blob signing.
- How to connect Rails to Cloud SQL using the Cloud SQL Auth Proxy (and why opening to `0.0.0.0/0` is an anti-pattern).
- How to manage secrets securely using Google Cloud Secret Manager.
- How to run multi-container setups (`web` + Solid Queue `worker` + `cloudsql-proxy` sidecar) in Docker Compose and deploy them to Cloud Run.
- How to build AI-powered background features (like the **NanoBanana Auto-Cover Generator**) using Solid Queue and Gemini.

Let's get started!

