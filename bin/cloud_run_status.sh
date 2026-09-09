#!/bin/bash
# bin/cloud_run_status.sh — Infer Cloud Run URL and fetch status dashboard / telemetry
#
# Usage:
#   bin/cloud_run_status.sh [URL] [--json] [--url-only]
#   just cloud-run-status
#
set -euo pipefail

MODE="pretty"
OVERRIDE_URL=""

for arg in "$@"; do
  case "$arg" in
    --json)
      MODE="json"
      ;;
    --url-only)
      MODE="url"
      ;;
    http://*|https://*)
      OVERRIDE_URL="$arg"
      ;;
  esac
done

# Source .env if available
if [ -f .env ]; then
  set -a; source .env 2>/dev/null || true; set +a
elif [ -f ../.env ]; then
  set -a; source ../.env 2>/dev/null || true; set +a
fi

PROJECT_ID="${GOOGLE_CLOUD_PROJECT:-${GCP_PROJECT_ID:-}}"
REGION="${GOOGLE_CLOUD_REGION:-${REGION:-europe-west1}}"

CLOUD_RUN_URL="$OVERRIDE_URL"

# 1. Try resolving via Terraform Output
if [ -z "$CLOUD_RUN_URL" ] && [ -d "iac" ]; then
  TF_URL=$(cd iac && terraform output -raw cloud_run_url 2>/dev/null || true)
  if [[ "$TF_URL" =~ ^https?:// ]]; then
    CLOUD_RUN_URL="$TF_URL"
  fi
fi

# 2. Try resolving via CLOUD_RUN_URL env var
if [ -z "$CLOUD_RUN_URL" ] && [ -n "${CLOUD_RUN_URL:-}" ]; then
  CLOUD_RUN_URL="${CLOUD_RUN_URL}"
fi

# 3. Try resolving via gcloud
if [ -z "$CLOUD_RUN_URL" ]; then
  # Try active project from gcloud if not set
  if [ -z "$PROJECT_ID" ]; then
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null || true)
  fi

  if [ -n "$PROJECT_ID" ]; then
    # Try finding rails-app service
    SVC_NAME="${PROJECT_ID}-rails-app"
    GCLOUD_URL=$(gcloud run services describe "$SVC_NAME" --project="$PROJECT_ID" --region="$REGION" --format="value(status.url)" 2>/dev/null || true)
    
    if [ -z "$GCLOUD_URL" ]; then
      # Fallback: find any rails service in project
      GCLOUD_URL=$(gcloud run services list --project="$PROJECT_ID" --filter="metadata.name ~ rails" --format="value(status.url)" 2>/dev/null | head -n 1 || true)
    fi

    if [[ "$GCLOUD_URL" =~ ^https?:// ]]; then
      CLOUD_RUN_URL="$GCLOUD_URL"
    fi
  fi
fi

if [ -z "$CLOUD_RUN_URL" ]; then
  echo "❌ Could not resolve Cloud Run endpoint URL via Terraform or gcloud." >&2
  echo "👉 Provide it as an argument: bin/cloud_run_status.sh https://<your-service>.run.app" >&2
  exit 1
fi

# Strip trailing slash
CLOUD_RUN_URL="${CLOUD_RUN_URL%/}"

if [ "$MODE" == "url" ]; then
  echo "$CLOUD_RUN_URL"
  exit 0
fi

STATUS_JSON=$(curl -s -f "${CLOUD_RUN_URL}/status.json" 2>/dev/null || true)

if [ -z "$STATUS_JSON" ]; then
  # Check if /up responds at least
  UP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${CLOUD_RUN_URL}/up" 2>/dev/null || echo "000")
  echo "❌ Failed to fetch ${CLOUD_RUN_URL}/status.json (Healthcheck /up returned HTTP ${UP_CODE})" >&2
  exit 1
fi

if [ "$MODE" == "json" ]; then
  if command -v jq >/dev/null 2>&1; then
    echo "$STATUS_JSON" | jq .
  else
    echo "$STATUS_JSON"
  fi
  exit 0
fi

# Pretty formatting with ruby/python
ruby -rjson -e '
  data = JSON.parse(ARGV[0]) rescue nil
  url = ARGV[1]

  unless data
    puts "❌ Invalid JSON received from #{url}/status.json"
    exit 1
  end

  sys = data["system"] || {}
  step = data["workshop_step"] || {}
  run_env = data["run_env"] || {}
  db = data["database"] || {}
  storage = data["storage"] || {}
  ai = data["ai"] || {}
  jobs = data["jobs"] || {}

  puts "\n🌐 \e[1;36mCloud Run Live Status\e[0m"
  puts "─────────────────────────────────────────────────────────────"
  puts "  🔗 URL:            \e[1;34m#{url}\e[0m"
  puts "  🧭 Dashboard:      \e[4m#{url}/status\e[0m"
  puts "  💚 Healthcheck:    \e[32m#{url}/up (200 OK)\e[0m"
  puts "  🏷️  App Version:    v#{sys["app_version"]} (Rails #{sys["rails_version"]}, Ruby #{sys["ruby_version"]})"
  puts "  🎯 Workshop Step:  \e[1;33mStep #{step["number"]}\e[0m (#{step["description"]})"
  puts "─────────────────────────────────────────────────────────────"
  puts "  #{run_env["badge"] || "🚀 Runtime"}:    #{run_env["details"]}"
  puts "  #{db["badge"] || "🐘 Database"}:   #{db["details"]}"
  puts "  #{storage["badge"] || "☁️ Storage"}:    #{storage["details"]}"
  puts "  #{ai["badge"] || "🍌 GenAI"}:      #{ai["details"]}"
  puts "  #{jobs["badge"] || "⚡ Jobs"}:       #{jobs["pending_count"].to_i} pending, #{jobs["failed_count"].to_i} failed"
  puts "─────────────────────────────────────────────────────────────"
  puts "  📊 Content:        #{sys["posts_count"]} Posts · #{sys["admin_users_count"]} Registered Users"
  puts ""
' "$STATUS_JSON" "$CLOUD_RUN_URL"
