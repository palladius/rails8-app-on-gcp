#!/usr/bin/env python3
"""Deterministic Google Cloud Architecture Diagram Generator for Rails 8 on GCP.

Generates:
1. Canonical production reference architecture diagram (arch_diagram.png).
2. Progressive evolutionary frames and animated GIF (arch_evolution.gif).
"""

import argparse
import os
import shutil
import sys
from pathlib import Path

from diagrams import Diagram, Cluster, Edge
from diagrams.gcp.compute import Run
from diagrams.gcp.database import SQL
from diagrams.gcp.storage import Storage
from diagrams.gcp.security import SecretManager, Iam
from diagrams.gcp.ml import VertexAI
from diagrams.gcp.devtools import Build, ContainerRegistry
from diagrams.gcp.network import LoadBalancing
from diagrams.gcp.operations import Logging, Monitoring
from diagrams.onprem.client import Users
from PIL import Image

REPO_ROOT = Path(__file__).resolve().parent.parent
ASSETS_DIR = REPO_ROOT / "assets"
WORKSHOP_IMAGES_DIR = REPO_ROOT / "workshop" / "assets" / "images"
OUTPUT_TMP_DIR = Path(__file__).resolve().parent / "output"

GRAPH_ATTRS = {
    "fontsize": "28",
    "fontname": "Helvetica",
    "bgcolor": "white",
    "pad": "0.6",
    "splines": "spline",
}

NODE_ATTRS = {
    "fontsize": "13",
    "fontname": "Helvetica",
}

EDGE_ATTRS = {
    "fontsize": "11",
    "fontname": "Helvetica",
    "color": "#4285F4",
}


def ensure_dirs():
    ASSETS_DIR.mkdir(parents=True, exist_ok=True)
    WORKSHOP_IMAGES_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT_TMP_DIR.mkdir(parents=True, exist_ok=True)


def generate_canonical():
    """Generates the canonical production GCP architecture diagram."""
    print("🎨 Generating Canonical Google Cloud Architecture Diagram...")
    out_filename = OUTPUT_TMP_DIR / "arch_diagram"
    
    with Diagram(
        "Rails 8 on Google Cloud: Production Reference Architecture",
        filename=str(out_filename),
        show=False,
        direction="LR",
        graph_attr=GRAPH_ATTRS,
        node_attr=NODE_ATTRS,
        edge_attr=EDGE_ATTRS,
        outformat="png",
    ):
        users = Users("Web & Mobile\nUsers")

        with Cluster("Google Cloud Ingress & Perimeter"):
            lb = LoadBalancing("Cloud Load Balancing\n& Custom Domain")

        with Cluster("Cloud Run Service (Multi-Container Pod)"):
            with Cluster("Container: web"):
                web = Run("Puma Server\n(Rails 8.1 Monolith)")

            with Cluster("Container: worker"):
                worker = Run("Solid Queue Worker\n(Background Jobs)")

            with Cluster("Container: sidecar"):
                proxy = Run("Cloud SQL Auth Proxy\n(mTLS Tunnel)")

        with Cluster("Google Cloud Managed Persistence"):
            db = SQL("Cloud SQL PostgreSQL\n(Managed Database)")
            gcs = Storage("Google Cloud Storage\n(Private Media Bucket)")

        with Cluster("Google Cloud Security & Identity"):
            sm = SecretManager("Secret Manager\n(RAILS_MASTER_KEY)")
            iam = Iam("Cloud IAM\n(rails-app-sa & Blob Signer)")

        with Cluster("Google Cloud GenAI Tier"):
            vertex = VertexAI("Vertex AI\n(Nano Banana & Gemini)")

        with Cluster("CI/CD & DevOps Automation"):
            cb = Build("Cloud Build\n(Automated Pipeline)")
            ar = ContainerRegistry("Artifact Registry\n(OCI Images)")

        with Cluster("Observability & Telemetry"):
            ops = [Logging("Cloud Logging\n(Structured JSON)"), Monitoring("Cloud Monitoring\n(Metrics & Uptime)")]

        # Connections
        users >> Edge(label="HTTPS / Ingress", color="#1a73e8", style="bold") >> lb >> Edge(label="Port 8080", color="#1a73e8") >> web
        
        # In-pod async job queue
        web >> Edge(label="Enqueue Jobs\n(Solid Queue DB)", color="#f9ab00", style="dashed") >> worker

        # Database connections via localhost Cloud SQL proxy
        web >> Edge(label="localhost:5432", color="#188038") >> proxy
        worker >> Edge(label="localhost:5432", color="#188038") >> proxy
        proxy >> Edge(label="mTLS Encrypted Tunnel\n(No Public IP)", color="#188038", style="bold") >> db

        # Object Storage
        web >> Edge(label="ActiveStorage\n(IAM Signed URLs)", color="#4285F4") >> gcs
        worker >> Edge(label="Direct Blob Attach\n(iam: true)", color="#4285F4") >> gcs

        # Security & Identity
        sm >> Edge(label="Runtime Secret Injection", color="#d93025", style="dotted") >> web
        sm >> Edge(color="#d93025", style="dotted") >> worker
        iam >> Edge(label="Blob Signing & Proxy Client", color="#d93025", style="dotted") >> web
        iam >> Edge(color="#d93025", style="dotted") >> worker

        # GenAI Async Pipeline
        worker >> Edge(label="Nano Banana Imagen 3\n& Audio Summaries", color="#a142f4", style="bold") >> vertex

        # CI/CD deployment
        cb >> Edge(label="Build Containers") >> ar >> Edge(label="Deploy Revision") >> web

        # Telemetry
        web >> Edge(style="dotted", color="#5f6368") >> ops
        worker >> Edge(style="dotted", color="#5f6368") >> ops

    generated_png = OUTPUT_TMP_DIR / "arch_diagram.png"
    if not generated_png.exists():
        raise RuntimeError(f"Failed to generate {generated_png}")

    # Copy to target asset locations
    dest_repo = ASSETS_DIR / "arch_diagram.png"
    dest_workshop = WORKSHOP_IMAGES_DIR / "arch_diagram.png"
    shutil.copyfile(generated_png, dest_repo)
    shutil.copyfile(generated_png, dest_workshop)
    print(f"✅ Canonical diagram saved to:\n   - {dest_repo}\n   - {dest_workshop}")


def main():
    parser = argparse.ArgumentParser(description="Generate Rails 8 on GCP architecture diagrams.")
    parser.add_argument("--canonical", action="store_true", help="Generate canonical arch_diagram.png")
    parser.add_argument("--evolution", action="store_true", help="Generate arch_evolution.gif")
    parser.add_argument("--all", action="store_true", help="Generate both canonical and evolution diagrams")
    args = parser.parse_args()

    ensure_dirs()

    if not (args.canonical or args.evolution or args.all):
        args.all = True

    if args.canonical or args.all:
        generate_canonical()

    return 0


if __name__ == "__main__":
    sys.exit(main())
