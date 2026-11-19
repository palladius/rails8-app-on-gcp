# 📜 Codelab Changelog (`rails8-on-google-cloud`)

This file tracks the synchronized changes between:
1. **GitHub Source of Truth**: [`workshop/CODELAB.md`](./CODELAB.md) (and generated `docs/` via `just build-ghpages`)
2. **Google DevSite Codelab Mirror**: `rails8-on-google-cloud` (`index.lab.md`, synced via `ruby bin/sync_devsite_codelab.rb`)

The current version in [`workshop/CODELAB_VERSION`](./CODELAB_VERSION) is embedded in the last page (`Conclusion and Clean Up`) of both Codelabs in small italics and verified by automated contract tests (`test/test_codelab_sync_and_contracts.rb`).

---

## [2.5.3] - 2026-11-18 (Live checks in the evals; honest Clean Up)

- **Step 6**: a note explains the new `[LIVE]` line of `just workshop-eval 6` (it asks Cloud Run what is deployed; a warning does not fail the run). Steps 3 and 4 get a smaller live check, with no text change.
- **Clean Up**: a warning says that Option 1 currently fails and leaves Cloud SQL running; use Option 2 for a dedicated workshop project.

## [2.5.2] - 2026-11-18 (Folder-independent `cd`; where to claim credits)

- **Steps 3, 4 and 6**: `cd "$(git rev-parse --show-toplevel)/blog"` works from the repository root and from inside `blog/`.
- **Step 0**: a note says the credits banner is only in the Google-hosted copy of the codelab.

## [2.5.1] - 2026-11-18 (Works from `blog/`; honest timings; from friction log FL015)

- **Step 4 and Step 6**: `just workshop-rewind 2` and `just workshop-restore-gold` now work from inside `blog/`, where Step 3 leaves you (fix in `blog/justfile`, no text change).
- **Step 5**: the credentials check runs from any folder.
- **Step 3**: title and intro no longer promise "3 minutes"; a source deploy takes about six.
- **Step 7**: a note says the AI cover can take a few minutes.

## [2.5.0] - 2026-11-18 (Step 6: secrets from Secret Manager; fixes from friction log FL014)

- **Step 6**: split into Deploy 4a (`gcloud run compose up`: three containers, no secrets, still on SQLite) and Deploy 4b (one `gcloud run services update` mounting `RAILS_MASTER_KEY` and `DB_PASSWORD` from Secret Manager on `web` and `worker`, and switching to `rails-cloudrun-sa`). The previous last command of the step failed with a type-conflict error. A new check shows that the service holds only `secretKeyRef` references.
- **Step 6**: the migration job is now an optional section after the deploy; it no longer needs a `DATABASE_URL` with the password inside.
- **Step 5**: `SQL_INSTANCE_NAME` comes from `gcloud sql instances list`; the `DB_PASSWORD` export is gone.
- **Step 7 and Step 8**: the local console examples fetch `DB_PASSWORD` from Secret Manager themselves.

## [2.4.0] - 2026-11-16 (Constitution v1.5.0: Any Harness & Honest Local AI Story)

- **Step 0 (Constitution §12)**: Any AI coding harness works. `CLAUDE.md` and `GEMINI.md` are symlinks to `AGENTS.md`, and the repo's skills are linked under `.claude/skills` and `.agents/skills`. Antigravity with a Gmail account stays the zero-cost default.
- **Step 2 and Step 7 (Constitution §11)**: The codelab now says that the local Docker Compose stack holds no Google credentials, so a new post gets the bundled placeholder cover there; the AI-generated poster appears on Cloud Run in Step 7. Step 7 no longer claims that local development authenticates to Vertex AI out of the box.

## [2.3.0] - 2026-10-08 (Daniel Strebel's Friction Log & Guillaume Laforge's Agentic `.md` Switcher)

- **Constitution §11 & Step 6 / Step 7 (`P0-1` — Zero `GEMINI_API_KEY`)**:
  - Abolished `GEMINI_API_KEY` across `workshop/CODELAB.md`, `workshop/SKELETON.md`, `blog/compose.prod.yaml`, and `blog/lib/nanobanana.rb`. All GenAI workloads authenticate exclusively via keyless Vertex AI Application Default Credentials (`GOOGLE_CLOUD_PROJECT` + `roles/aiplatform.user`).
- **Step 0 (`REQ-01`, `REQ-02`)**:
  - Added warning callout against running interactive `gcloud init` inside Cloud Shell or pre-configured workshop VMs.
  - Highlighted Docker Compose, VS Code DevContainers (`.devcontainer/devcontainer.json`), and Cloud Shell as the `< 2 min` zero-compile fast-track, and documented native `libyaml-dev`/`libssl-dev` packages for optional host `rbenv` builds.
- **Step 1 (`REQ-04`)**:
  - Added `.env.example` symlink alias alongside `.env.dist` and documented `GOOGLE_CLOUD_PROJECT`, `GOOGLE_CLOUD_REGION`, `GOOGLE_CLOUD_LOCATION=global`, and `PORT`.
- **Step 3 (`REQ-05`, `REQ-A6`)**:
  - Added `bundle lock --add-platform x86_64-linux` and `cloudbuild.yaml` (`--cache-from`) troubleshooting guidance, and clarified HTTPS/TLS endpoint terminology.
- **Step 5 & Step 6 (`REQ-03`, `REQ-A9`, `REQ-A10`)**:
  - Removed distracting `workshop-fun-secret` playground snippet, explained `RAILS_MASTER_KEY` cryptographic pairing, and bound `--set-secrets="RAILS_MASTER_KEY=rails-master-key:latest"` in Step 6's `gcloud run services update blog`.
- **Step 7, Step 8 & Conclusion (`REQ-06`, `REQ-07`, `REQ-08`, `P0-2`)**:
  - Added explicit `roles/aiplatform.user` IAM binding check in Step 7, removed raw `TODO(riccardo)` placeholders, documented the `IAP_MOCK_EMAIL` fake-login warning banner in Step 8, and added surgical CLI + Terraform teardown commands in `Conclusion & Clean Up`.
- **Visualizer & Static Build (`REQ-09` — Guillaume Laforge's `.md` Switcher & Agentic A11y)**:
  - Added `📋 Copy Step .md`, `📄 View .md`, and `🤖 Full .md` buttons, `/codelab.md` and `/llms.txt` endpoints, `<link rel="alternate" type="text/markdown">`, and `<aside role="note" aria-label="AI Agent Instructions">`.

---

## [2.2.2] - 2026-10-01 (Friction Log 4, `palladius/rails8-app-on-gcp#169`)

- **Step 6 (Deploy 4)**: removed `--allow-unauthenticated` from the final `gcloud run services update blog ...` command. That flag belongs to `gcloud run deploy`; `services update` rejects it with `unrecognized arguments` and applies nothing, so `--service-account=$RUN_SA` was never set and the service kept running as the Default Compute SA. Public access already comes from the Step 3 deploy.

---

## [2.2.1] - 2026-10-01 (Friction Log 4, `palladius/rails8-app-on-gcp#165`)

- **Steps 2 & 3**: the default seeded admin password changed from `Ch4ng3m3!!1` to `Ch4ng3m3-1`. In an interactive bash/zsh, `!!` outside single quotes is history expansion, so pasting the Deploy 1 block mangled the `--set-env-vars` value and corrupted the deploy.

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
