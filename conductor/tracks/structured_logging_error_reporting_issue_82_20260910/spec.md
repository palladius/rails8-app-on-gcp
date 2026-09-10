# Specification: Native Google Cloud Structured JSON Logging & Error Reporting (Issue #82)

## 1. Overview
This track delivers native, zero-gem **Structured JSON Logging** for Google Cloud Logging and automated exception group tracking in **Google Cloud Error Reporting** via container `STDERR` streams on Cloud Run. In addition, it modernizes the user-facing 500 error page to conform with Google/Gemini aesthetic guidelines (`product-guidelines.md`) and automates high-resolution "Before" and "After" screenshot captures via Playwright (`workshop/screenshots/`) for release notes and bragging rights ahead of the Modena premiere (Oct 2).

## 2. Functional Requirements

### 2.1 Google Cloud Structured JSON Logging (`config/environments/production.rb`)
- Implement a lightweight, zero-gem `GoogleJsonFormatter < ActiveSupport::Logger::SimpleFormatter`.
- In `production.rb`, format log lines as single-line JSON with standard GCP fields:
  - `severity`: Standard syslog/Cloud Logging severity levels (`DEFAULT`, `DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`).
  - `time`: RFC3339 / ISO8601 timestamp with fractional seconds.
  - `message`: Log text.
  - `logging.googleapis.com/trace`: Google Cloud Trace ID extracted from `X-Cloud-Trace-Context` or trace headers if present.
  - `logging.googleapis.com/sourceLocation`: File, line, and method information when applicable.
- Ensure logging falls back safely without raising errors if message is nil or binary.
- Allow optional local testing in development via environment variable `LOG_FORMAT=json`.

### 2.2 Native Google Cloud Error Reporting via STDERR
- Google Cloud Error Reporting continuously scans container `STDERR` on Cloud Run for stack traces matching standard formats.
- When an unhandled 500 exception occurs in Rails:
  - Format the exception name, message, request context, and full backtrace.
  - Emit directly to `$stderr` in a format that Error Reporting's regex parser natively recognizes.
  - Ensure this does not interfere with standard user-facing HTTP 500 responses.

### 2.3 Diagnostic Test Route (`/boom`)
- Add a demo/diagnostic route `GET /boom` (configurable or enabled in development/test/staging/production with safety controls).
- When triggered, it deliberately raises a descriptive `RuntimeError: "💥 Deliberate Boom: Verifying Google Cloud Error Reporting & Structured Logging!"`.
- Serves as the repeatable live-demo trigger for workshops and screenshot automation.

### 2.4 Googley / Gemini 500 Error Page
- Modernize `blog/public/500.html` (and dynamic error views if applicable) to match `product-guidelines.md`:
  - Premium Google/Gemini card aesthetic with smooth gradients, friendly typography, and Google colors.
  - Friendly, instructional error message with Request ID for debugging.
  - Quick action buttons ("Back to Home", "Retry").
  - Clean responsive styling that looks great on mobile and desktop.

### 2.5 Automated Before & After Screenshots for Modena Brag
- Use the Playwright screenshot harness (`workshop/screenshots/`):
  - Script to capture the "Before" error UI state (the original generic Rails 500 page).
  - Script to capture the "After" error UI state (the new Googley 500 page).
  - Output screenshots saved to `workshop/assets/screenshots/` (e.g. `issue-82-error-before.png` and `issue-82-error-after.png`).
  - Integrated into `workshop/skeleton.yaml` declarative screenshots and runnable via `just screenshots`.

## 3. Non-Functional Requirements
- **Zero Heavy Gems:** Absolutely no bulky third-party APM or logging gems (e.g., no google-cloud-logging gem dependency needed; native Cloud Run stdout/stderr ingestion).
- **Fast Execution & Invariant Safety:** `just test` must execute in < 5 seconds and pass 100% without external internet/GCP dependencies.
- **Localhost Invariant:** All logging and error handling must function locally without GCP credentials or active network access.

## 4. Acceptance Criteria
- [ ] `GoogleJsonFormatter` added and enabled in `blog/config/environments/production.rb` (and optionally when `LOG_FORMAT=json`).
- [ ] Unhandled 500 exceptions output structured stack traces to `STDERR` suitable for Cloud Error Reporting ingestion.
- [ ] `GET /boom` diagnostic endpoint operational and verified by automated controller tests.
- [ ] `blog/public/500.html` updated to Google/Gemini aesthetic guidelines.
- [ ] Playwright automated screenshot script created to capture Before & After error pages.
- [ ] `workshop/skeleton.yaml` updated with screenshot declarations.
- [ ] `just test` passes with 0 failures.

## 5. Out of Scope
- External proprietary APM agents (Datadog, New Relic).
- Heavy Cloud Logging SDK API streaming (Cloud Run automatically ingests container stdout/stderr into Cloud Logging at zero CPU/network cost).
