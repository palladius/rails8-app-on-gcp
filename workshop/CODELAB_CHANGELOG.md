# 📜 Codelab Changelog (`rails8-on-google-cloud`)

This file tracks the synchronized changes between:
1. **GitHub Source of Truth**: [`workshop/CODELAB.md`](./CODELAB.md) (and generated `docs/` via `just build-ghpages`)
2. **Google DevSite Codelab Mirror**: `rails8-on-google-cloud` (`index.lab.md`, synced via `ruby bin/sync_devsite_codelab.rb`)

The current version in [`workshop/CODELAB_VERSION`](./CODELAB_VERSION) is embedded in the last page (`Conclusion and Clean Up`) of both Codelabs in small italics and verified by automated contract tests (`test/test_codelab_sync_and_contracts.rb`).

---

## [2.2.0] - 2026-09-24 (Emiliano Della Casa's Friction Log `#153` Remediation)

### 🏗️ Architectural & Codelab Fixes (`palladius/rails8-app-on-gcp#153`)
- **Step 2 (Getting Started)**:
  - Added collapsible instructions (`<details>`) for **Option A: Create a brand-new GCP project via CLI** (`gcloud projects create` + `gcloud billing projects link`) alongside **Option B: Reuse an existing project**.
  - Added automated `master.key` + `credentials.yml.enc` bootstrap (`bin/ensure_workshop_credentials.rb` hooked into `just workshop-test` and `just terraform-apply`), preventing `GENESIS_CREATORS_CREDENTIALS_MD5` (`7b856d06f492f293bea59a5323150d8c`) from causing `ActiveSupport::MessageEncryptor::InvalidMessage` crashes in Cloud Run.
- **Step 3 (First Deployment to Cloud Run)**:
  - Fixed `ActionDispatch::HostAuthorization` blocker when testing locally in Google Cloud Shell Web Preview (`*.cloudshell.dev`).
  - Added explicit cleanup after the `Deploy 2` (`SOLID_QUEUE_IN_PUMA=true`) pedagogical experiment (`--remove-env-vars SOLID_QUEUE_IN_PUMA --max-instances 1`) so subsequent steps do not suffer from 512 MiB OOM crashes or multi-instance ephemeral SQLite session splitting.
- **Step 4 (Active Storage with GCS) & Step 5 (Production Readiness with Terraform)**:
  - **Service Account Unification (`RUN_SA`)**: Replaced all uses of the Default Compute Service Account (`${PROJECT_NUMBER}-compute@developer.gserviceaccount.com`) with the dedicated Terraform-managed identity `RUN_SA="rails-cloudrun-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com"`, matching `blog/config/storage.yml`.
  - Fixed `Deploy 3` command to explicitly pass `--set-env-vars="RAILS_MASTER_KEY=$(cat config/master.key),GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT,ACTIVE_STORAGE_SERVICE=google" --service-account="$RUN_SA" --max-instances=1`.
  - Fixed `just check-infra` verification URL check (`PROJECT_NUMBER` fallback + `grep -q "200"`).
- **Step 6 (Deploy with Cloud Run Compose)**:
  - Documented and remediated the `gcloud beta run compose up` compiled binary limitation (which omits `serviceAccountName:` and resets the service to the Default Compute SA) by immediately applying `gcloud run services update blog --region=$GOOGLE_CLOUD_REGION --service-account="rails-cloudrun-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" --allow-unauthenticated`.
  - Fixed `db/seeds.rb` idempotency (`find_or_create_by!`) and single-container `MIGRATE_AND_SEED=true` boot sequence.
- **Step 8 (Conclusion and Clean Up)**:
  - Added subtle small-italic version stamp at the bottom of the final page (`*Codelab Version: v2.2.0 ...*`) to visually verify parity between GitHub and Google DevSite.

---

## [2.1.0] - 2026-08-26 (FL_001 Remediation)
- Initial synchronization between `workshop/CODELAB.md` and DevSite `index.lab.md`.
- Added `--region=$GOOGLE_CLOUD_REGION` across `gcloud run` commands and switched container builds to `--source .`.
