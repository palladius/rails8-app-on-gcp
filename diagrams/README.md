# 📊 Architecture Diagrams as Code

Deterministic Google Cloud architecture diagram generator for the `rails8-app-on-gcp` project and workshop.

## Features
- 🏗️ **Deterministic & Code-Defined:** Built using the Python `diagrams` library (`mingrammer/diagrams`) and official Google Cloud icons.
- 🚀 **Full Production Blueprint (`arch_diagram.png`):** Highlights all Google Cloud products utilized in the final state (Cloud Run multi-container pod, Cloud SQL Postgres, private GCS with IAM signed URLs, Secret Manager, Vertex AI Nano Banana/Gemini, and Cloud Build CI/CD).
- 🎞️ **Workshop Evolution GIF (`arch_evolution.gif`):** Renders sequential milestone frames of the workshop architecture (Local SQLite -> Cloud SQL -> GCS -> Cloud Run -> Vertex AI) assembled into a smooth animated GIF.

## Prerequisites
- `uv` Python package manager
- Graphviz (`dot`) installed locally

## Usage
Run directly from repo root via `just`:
```bash
# Generate canonical architecture diagram
just diagram

# Generate progressive evolution frames & GIF
just diagram-evolution

# Generate all diagrams
just diagrams
```
