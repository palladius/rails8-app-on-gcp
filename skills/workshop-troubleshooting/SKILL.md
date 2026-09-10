---
name: workshop-troubleshooting
description: Comprehensive troubleshooting guide for Rails 8 on Google Cloud workshop. Use when diagnosing errors, container crashes, HTTP 500s, Cloud Run startup failures, billing issues, Cloud SQL suspension, or local tooling problems.
---

# 🩺 Rails 8 on GCP Workshop Troubleshooting

When encountering errors during workshop execution, deployment to Google Cloud, or local development, use this skill to quickly diagnose the root cause and apply verified recovery procedures.

---

## 🚦 Fast Triage Matrix

Find your symptom below and consult the corresponding specialized reference guide:

| Area | Common Symptoms | Reference Guide |
|---|---|---|
| ☁️ **Cloud Run & Containers** | HTTP 500 on web request, startup probe failures, container crash loops, inspecting stack traces. | [`references/cloud-run.md`](references/cloud-run.md) |
| 💳 **GCP Billing & IAM** | `BillingNotEnabled`, Cloud SQL entering `SUSPENDED` (`BILLING_ISSUE`), ADC authentication errors. | [`references/gcp-billing-iam.md`](references/gcp-billing-iam.md) |
| 🐘 **Database & Storage** | `relation "solid_queue_jobs" does not exist`, `Invalid bucket name: '-activestorage-...'`, missing admin user banner. | [`references/database-storage.md`](references/database-storage.md) |
| 🛠️ **Local Toolchain** | `Bundler::GemNotFound` in Git worktree, Docker Compose port collisions, `just` runner execution errors. | [`references/local-toolchain.md`](references/local-toolchain.md) |

---

## ⚡ First Line of Defense: Automated Diagnostics

Before digging through logs manually, always run the automated pre-flight diagnostics:

```bash
just workshop-test
```

This validates your active gcloud account, project configuration, billing account status, Application Default Credentials (ADC), and Rails master key in under 3 seconds.
