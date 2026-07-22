# GCP ActiveStorage UAT Acceptance Plan

This document outlines the testing plan to ensure the GCP infrastructure and ActiveStorage configuration are working flawlessly. The plan is split into an automated portion (the 95%) and a manual user acceptance portion (the final 5%).

## ✅ 95% Automated Tests (Passed)

The following tests have been executed via automation and confirmed passing:

1. **Terraform Apply Validation**:
   - `terraform validate` succeeded.
   - `terraform apply` succeeded in `palladius-genai`.
   - All 7 resources (3 buckets, 1 Secret Manager secret, 1 Secret IAM binding, 1 Service Account, 1 SA IAM binding) created successfully.

2. **GCP Setup Verification Script**:
   - Run: `./iac/check_gcp_setup.sh`
   - Confirmed existence of `palladius-genai-activestorage-dev`
   - Confirmed existence of `palladius-genai-activestorage-test`
   - Confirmed existence of `palladius-genai-activestorage-prod`
   - Confirmed existence of SA `rails-cloudrun-sa@palladius-genai.iam.gserviceaccount.com`
   - Confirmed existence of secret `rails-master-key`

3. **Rails Codebase Configuration**:
   - GCS configuration added to `config/storage.yml`.
   - Environment files (`config/environments/development.rb`, `test.rb`, `production.rb`) set `config.active_storage.service` to `google_dev`, `google_test`, and `google_prod` respectively.

---

## 🙋‍♂️ 5% Manual UAT Steps (Your Turn)

This is the remaining 5% that must be executed manually to confirm end-to-end functionality in your browser.

**Goal**: Verify that a user can successfully boot the Rails app locally, upload a file, and have it persist into the GCP Cloud Storage dev bucket.

### Step 1: Boot the Application
Run the Rails app locally (e.g., using `just s` or `bin/rails s` in the `blog/` folder).

### Step 2: Upload Media
1. Open the application in your browser (`http://localhost:3000`).
2. Navigate to a form that supports ActiveStorage file uploads (e.g., creating a new Post with an image).
3. Upload an image and save.
4. Verify the image renders correctly on the page.

### Step 3: Verify in GCP
1. Go to the terminal.
2. Run the validation script again:
   ```bash
   cd emiliano-new-app/iac
   export GOOGLE_APPLICATION_CREDENTIALS=../../private/gcp-key.json
   ./check_gcp_setup.sh
   ```
3. Observe the output! Under the "1️⃣ Checking ActiveStorage GCS Buckets..." section, you should see the `dev` bucket's media count go from `0` to `1` (or more, depending on variations).

### Sign-off
If the media count increases and the app works, we are 100% complete!

### Step 4: Verify GCS Terraform State on a Virgin Project
1. Change the `GOOGLE_CLOUD_PROJECT` in `.env` to a completely new (virgin) GCP project id.
2. Run `cd emiliano-new-app/iac && ./tf-init.sh` to initialize the GCS backend.
3. Run `terraform apply -var="project_id=$GOOGLE_CLOUD_PROJECT"`.
4. Ensure the state is properly captured in the newly created `${GOOGLE_CLOUD_PROJECT}-tfstate` GCS bucket without any collisions or local state conflicts.
