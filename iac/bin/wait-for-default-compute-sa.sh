#!/usr/bin/env bash
# ==============================================================================
# Wait until Google has created the Default Compute Service Account (issue #164).
# Usage: wait-for-default-compute-sa.sh <sa-email> <project-id>
# Env:   WAIT_ATTEMPTS (default 36) and WAIT_SLEEP seconds (default 5) = ~3 minutes.
#
# Only "not found" is worth waiting for. Any other gcloud error (permission denied,
# wrong account, API disabled, ...) cannot be fixed by waiting, so fail fast and show it.
# ==============================================================================
set -uo pipefail

sa="${1:?usage: $0 <sa-email> <project-id>}"
project="${2:?usage: $0 <sa-email> <project-id>}"
attempts="${WAIT_ATTEMPTS:-36}"
delay="${WAIT_SLEEP:-5}"

echo "Waiting for the Default Compute Service Account ${sa} (Google creates it lazily)..."
for ((i = 1; i <= attempts; i++)); do
  if out=$(gcloud iam service-accounts describe "${sa}" --project="${project}" 2>&1); then
    echo "Default Compute Service Account is ready."
    exit 0
  fi
  if grep -qiE 'NOT_FOUND|does not exist|Unknown service account' <<<"${out}"; then
    sleep "${delay}"
    continue
  fi
  {
    echo "gcloud failed with an error other than 'not found', so waiting will not help:"
    echo "${out}"
    echo "Check 'gcloud auth list': the active gcloud account must be allowed to read IAM on ${project}"
    echo "(Terraform itself uses GOOGLE_CLOUD_ACCOUNT / Application Default Credentials)."
  } >&2
  exit 1
done

echo "Timed out after ${attempts} attempts waiting for ${sa}. Re-run 'just terraform-apply'." >&2
exit 1
