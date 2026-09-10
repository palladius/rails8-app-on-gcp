# 🍌 Nano Banana Architecture Diagram Prompts

This document maintains the canonical prompt engineering specifications for **Nano Banana Pro** (Gemini 3 Pro Image / Imagen 3) to generate high-fidelity, production-grade cloud architecture diagrams for the **Rails 8 on Google Cloud** workshop.

---

## 🎯 Architecture Specifications (The Ground Truth)

Every prompt variant strictly adheres to the following structural topology:

1. **Centerpiece (The Monolith on Serverless Cloud Run)**:
   - A single, prominent **Google Cloud Run** container service box.
   - Inside Cloud Run, **3 vertically stacked sub-containers** displayed in monospace technical font:
     - `🌐 rails_app (puma :8080)` — Primary web request handler
     - `⚡ solid_queue (worker)` — Asynchronous background job processor
     - `🔒 cloud_sql_proxy (sidecar :5432)` — Secure local mTLS tunnel
2. **Left Side (Ingress & Security)**:
   - **Users / Web Traffic** hitting Cloud Run via HTTPS (:443).
   - **Google Cloud Secret Manager (SM)**: Injecting runtime database credentials and API keys directly into the Cloud Run service.
3. **Right Side (Managed Persistence & AI)**:
   - **Google Cloud SQL (PostgreSQL)**: Connected securely via encrypted mTLS from `cloud_sql_proxy`.
   - **Google Cloud Storage (GCS)**: Private bucket storing ActiveStorage blobs, accessed via IAM-signed short-lived URLs.
   - **Google Cloud Vertex AI**: GenAI pipeline for multimodal tasks (Nano Banana Imagen 3 cover generation and TTS podcast audio generation) triggered by `solid_queue`.
4. **Build Pipeline (CI/CD)**:
   - **Cloud Build** compiling multi-container images $\to$ storing in **Artifact Registry** $\to$ deploying revisions to **Cloud Run**.
5. **Branding & Visual Palette**:
   - Official Google Cloud colors: Google Blue (`#4285F4`), Green (`#34A853`), Yellow (`#FBBC05`), Red (`#EA4335`), and Neutral Slate (`#5F6368`).
   - Clean, highly legible text, zero AI gibberish/hallucinated text, crisp directional connection lines.

---

## 🎨 Prompt Variants

### Variant 1: Clean Flat Vector Enterprise Architecture (Default / Presentation)
```text
A professional, ultra-clean Google Cloud enterprise architecture diagram illustration on a pure white background.
In the center, a large Google Cloud Run container service box with rounded corners and subtle blue drop shadow. Inside the Cloud Run box, there are three neatly stacked vertical rectangular containers with monospace labels and icons:
1) "rails_app (puma :8080)" with a blue globe icon,
2) "solid_queue (worker)" with a yellow lightning bolt icon,
3) "cloud_sql_proxy (sidecar :5432)" with a green padlock icon.
On the left side, incoming web traffic arrows labeled "HTTPS :443" connect to Cloud Run. Above Cloud Run, an official red Google Cloud Secret Manager icon with a key symbol connects with a dotted line labeled "Runtime Secret Injection".
On the right side, two managed storage services:
- An official blue Google Cloud SQL PostgreSQL database cylinder with a bold green encrypted tunnel connection from the cloud_sql_proxy.
- An official blue Google Cloud Storage bucket icon connected with a blue arrow labeled "ActiveStorage Signed URLs".
Below Cloud Run, an official purple Google Cloud Vertex AI icon connected with a purple arrow from the solid_queue worker labeled "Nano Banana Imagen 3 & TTS".
On the far left, a Cloud Build icon connects to an Artifact Registry box that points to Cloud Run labeled "Deploy Revision".
Modern flat tech vector graphic, sharp edges, official Google Cloud color palette, legible monospace typography, high resolution 4k infographic, no clutter.
```

### Variant 2: Isometric 3D Cloud Infographic (Modern & Sleek)
```text
Sleek 3D isometric tech infographic showing a modern Google Cloud serverless architecture.
The central focus is a floating glass and aluminum platform representing a Google Cloud Run service. On this platform, three distinct modular server pods are stacked vertically in a sleek rack: top pod glowing cyan labeled "rails_app", middle pod glowing amber labeled "solid_queue", bottom pod glowing emerald green labeled "cloud_sql_proxy".
Glowing fiber-optic data tubes and holographic directional arrows connect the central platform to surrounding floating cloud infrastructure nodes:
- Left: incoming glowing blue data streams from users, and an elevated vault node representing Google Cloud Secret Manager.
- Right: a secure glowing blue database cylinder representing Google Cloud SQL PostgreSQL connected via a green laser tunnel, and a floating blue repository node representing Google Cloud Storage (GCS).
- Bottom: an iridescent purple prism node representing Google Cloud Vertex AI connected to the worker pod.
Clean minimalist studio lighting, light gray aesthetic background, high tech data visualization, photorealistic 3D render, 8k resolution, crisp technical typography.
```

---

## 💻 CLI Execution via Nano Banana Script

Generate variants directly using the local Nano Banana script:

```bash
# Variant 1: Clean Flat Vector Enterprise
just nanobanana variant="flat"

# Variant 2: Isometric 3D Infographic
just nanobanana variant="isometric"
```

