This we need to fix

1. [x] Terraform state should be on GCS and setup on GCS properly, taking from .env. If we migrate .env, no biggie, we have a different state :)
2. [x] There's should be a script like "just project-status" which says things like:
  1. - app GCS exists, contains N pics
  2. - DB exists, contains N posts /..
  3. - TF GCS exists, ...
  4. Lets use an aggressive default over configuration naming GCS buckets as {PROJECT_ID}-{SOMETHING_ELSE} so project auto determines the 2 above GCS buckets and low probability of collision (eg 2 tfstates for 2 projects).
  5. Note the awesomeness of this status script, it could have (or we branch in just-workshop-status) a nice short output which student can show to professor so we see where they are and where they're stuck.
3. [x] CHANGEMANAGEMENT: Lets avoid collisions. If I change a project id, i shouldnt overwrite a resources (eg a private key or a bucket folder, ...). Let's ensure all naming and folders on GCS and Secrets... have some sort of project_id embedded iin the name if we're at risk of collision. Let's not over do it! If Secret Manager has a rthing called "mypass" it shouldnt become "PROJECT_ID-mypass" unless there's a possibility that another project id writes this same secret in this very Project id, which seems unlikely.

## TODOs for Emiliano

* [23jul from Ricc] Emi, verifica se lo SKELETON.md ha senso.

## High-Priority Architectural & Workshop Items (2026-08)

4. [ ] **Day-1 Cloud Logging & Monitoring in Blueprint**:
   - Ensure the Rails 8 app produces structured JSON logs with trace correlation IDs for Cloud Run / Cloud Logging.
   - Wire up error reporting and basic ActiveSupport metrics out-of-the-box.
5. [ ] **Step 1: The Local Baseline, Seeds & Mailpit Experience**:
   - Update `seeds.rb` to read `ENV["ADMIN_EMAIL"]` and fire a password reset email via ActionMailer.
   - Guide students to catch the email on Mailpit (`http://localhost:8025`).
   - Add a `bin/rails console` password recovery exercise while Cloud SQL is provisioning.
6. [ ] **Step 8: Choose Your Own Adventure (The Quests)**:
   - Quest 1: Zero-Trust Google IAP & HTTPS Load Balancer (`iac/iap.tf` + `IapAuthenticatable` concern). Tracked in [conductor/tracks/iap_zero_trust_auth_20260828/](conductor/tracks/iap_zero_trust_auth_20260828/).
   - Quest 2: Structured Cloud Logging & Error Reporting Alerting.
   - Quest 3: `pgvector` Semantic Search & Gemini Multimodal RAG on Cloud SQL.
