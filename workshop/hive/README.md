# 🐝 Workshop Hive Leaderboard

The **Workshop Hive** is a live, gamified telemetry and leaderboard dashboard designed for the **Rails 8 on Google Cloud Workshop**.

It tracks students as they progress through each stage of the workshop (Step 1 through Step 7), pinging their live Cloud Run deployments to display real-time green/red health indicators.

---

## 🌟 Features

- **Horizontal Kanban Board:** Visual progression columns matching workshop milestones (Step 1 to Step 7).
- **Live Healthcheck Pings (🔴/🟢):** Periodically pings `/up` on every registered student app with sub-second timeout protection and latency stats.
- **Dynamic Google Sheets Data:** Reads students directly from a Google Sheet (populated via Google Form or API).
- **Quota-Protected Caching:** 30-second memory cache to respect Google Sheets API quotas.
- **Local Dev Mock Fallback:** Works out-of-the-box in local development with rich sample data even without GCP credentials or internet access.
- **Secure Service Account Auth:** Ingests GCP credentials securely via environment variables or Secret Manager without touching disk.

---

## 🚀 Quick Start (Local Development)

To start the Hive locally:

```bash
cd workshop/hive
bin/dev
```

Open [http://localhost:8080](http://localhost:8080) in your browser.  
If no Google Sheet credentials are provided, the app will smoothly run in mock mode with sample attendees.

---

## 🔐 Google Sheets Configuration & Authentication

The Hive reads from a Google Spreadsheet with columns like:
`Timestamp | Nickname | Cloud Run URL | Current Step`

### Environment Variables

| Variable | Description |
|---|---|
| `HIVE_SPREADSHEET_ID` | The ID of the Google Sheet (from its URL). |
| `HIVE_SHEET_RANGE` | Optional range (default: `A1:Z100`). |
| `HIVE_SERVICE_ACCOUNT_KEY_B64` | Base64-encoded Service Account JSON key (Recommended for Cloud Run). |
| `HIVE_SERVICE_ACCOUNT_JSON` | Raw Service Account JSON string. |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to a local JSON key file on disk (ignored by Git). |

### Giving Access to the Service Account
Share your Google Spreadsheet with the `client_email` of your Service Account with **Viewer** permissions.

---

## ☁️ Deploying to Google Cloud Run

To deploy the Hive to Cloud Run, simply configure `workshop/hive/.env` and run:

```bash
workshop/hive/bin/deploy
```

Or run manually:

```bash
gcloud run deploy workshop-hive \
  --source=workshop/hive \
  --project=palladius-genai \
  --region=europe-west1 \
  --allow-unauthenticated \
  --set-env-vars="HIVE_SPREADSHEET_ID=195OYMjc_ib2nysltnZE6cNmBw7xtXQ5WRC8igi7_AtM,HIVE_SHEET_GID=1095789823"
```

---

## 🧪 Running Tests

Run the test suite:

```bash
for f in workshop/hive/test/test_*.rb; do ruby "$f"; done
```
