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
from diagrams.generic.database import SQL as GenericSQL
from diagrams.generic.storage import Storage as GenericStorage
from diagrams.onprem.client import Users, Client
from PIL import Image

REPO_ROOT = Path(__file__).resolve().parent.parent
ASSETS_DIR = REPO_ROOT / "assets"
WORKSHOP_IMAGES_DIR = REPO_ROOT / "workshop" / "assets" / "images"
SLIDES_IMAGES_DIR = REPO_ROOT / "slides" / "images"
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
    SLIDES_IMAGES_DIR.mkdir(parents=True, exist_ok=True)
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

    dest_repo = ASSETS_DIR / "arch_diagram.png"
    dest_workshop = WORKSHOP_IMAGES_DIR / "arch_diagram.png"
    dest_slides = SLIDES_IMAGES_DIR / "arch_diagram.png"
    shutil.copyfile(generated_png, dest_repo)
    shutil.copyfile(generated_png, dest_workshop)
    shutil.copyfile(generated_png, dest_slides)
    print(f"✅ Canonical diagram saved to:\n   - {dest_repo}\n   - {dest_workshop}\n   - {dest_slides}")


def generate_evolution():
    """Generates sequential milestone photograms and compiles arch_evolution.gif."""
    print("🎞️ Generating Progressive Workshop Evolution Photograms...")
    frames = []

    # Frame 1: Local / Ephemeral Baseline
    f1_path = OUTPUT_TMP_DIR / "step1_local_baseline"
    with Diagram(
        "Step 1: Local Baseline [EPHEMERAL DB / STORAGE 🟡]",
        filename=str(f1_path),
        show=False,
        direction="LR",
        graph_attr=GRAPH_ATTRS,
        node_attr=NODE_ATTRS,
        edge_attr=EDGE_ATTRS,
        outformat="png",
    ):
        dev = Client("Developer Laptop\n(localhost:3000)")
        with Cluster("Local Host Machine"):
            web = Run("Puma Web Server\n(Rails 8 Baseline)")
            sqlite = GenericSQL("Local SQLite DB\n(Ephemeral Disk)")
            disk = GenericStorage("Local Disk Storage\n(public/uploads)")

        dev >> Edge(label="HTTP :3000") >> web
        web >> Edge(label="Direct File I/O") >> sqlite
        web >> Edge(label="ActiveStorage local") >> disk

    frames.append(OUTPUT_TMP_DIR / "step1_local_baseline.png")

    # Frame 2: Google Cloud SQL
    f2_path = OUTPUT_TMP_DIR / "step2_cloud_sql"
    with Diagram(
        "Step 3: Google Cloud SQL [PERSISTENT MANAGED DB 🐘]",
        filename=str(f2_path),
        show=False,
        direction="LR",
        graph_attr=GRAPH_ATTRS,
        node_attr=NODE_ATTRS,
        edge_attr=EDGE_ATTRS,
        outformat="png",
    ):
        dev = Client("Developer Laptop\n(localhost:3000)")
        with Cluster("Local Environment"):
            web = Run("Puma Web Server\n(Rails 8)")
            proxy = Run("Cloud SQL Auth Proxy\n(localhost:5432)")
            disk = GenericStorage("Local Disk Storage\n(Ephemeral Uploads)")

        with Cluster("Google Cloud Managed Persistence"):
            db = SQL("Cloud SQL PostgreSQL\n(Managed Instance)")

        dev >> Edge(label="HTTP :3000") >> web
        web >> Edge(label="localhost:5432") >> proxy
        proxy >> Edge(label="mTLS Encrypted Tunnel", color="#188038", style="bold") >> db
        web >> Edge(label="ActiveStorage local") >> disk

    frames.append(OUTPUT_TMP_DIR / "step2_cloud_sql.png")

    # Frame 3: Private GCS with IAM signed URLs
    f3_path = OUTPUT_TMP_DIR / "step3_cloud_storage"
    with Diagram(
        "Step 4: Private Cloud Storage [IAM SIGNED URLS 🪣]",
        filename=str(f3_path),
        show=False,
        direction="LR",
        graph_attr=GRAPH_ATTRS,
        node_attr=NODE_ATTRS,
        edge_attr=EDGE_ATTRS,
        outformat="png",
    ):
        dev = Client("Developer Laptop\n(localhost:3000)")
        with Cluster("Local Environment"):
            web = Run("Puma Web Server\n(Rails 8)")
            proxy = Run("Cloud SQL Auth Proxy\n(localhost:5432)")

        with Cluster("Google Cloud Managed Persistence"):
            db = SQL("Cloud SQL PostgreSQL\n(Managed Instance)")
            gcs = Storage("Google Cloud Storage\n(Private Bucket)")

        with Cluster("Google Cloud Security & Identity"):
            iam = Iam("Cloud IAM Credentials\n(Blob Signer)")

        dev >> Edge(label="HTTP :3000") >> web
        web >> Edge(label="localhost:5432") >> proxy
        proxy >> Edge(label="mTLS Tunnel", color="#188038") >> db
        web >> Edge(label="ActiveStorage (iam: true)", color="#4285F4") >> gcs
        iam >> Edge(label="Signed URL V4 Credentials", color="#d93025", style="dotted") >> web

    frames.append(OUTPUT_TMP_DIR / "step3_cloud_storage.png")

    # Frame 4: Cloud Run Multi-Container Pod
    f4_path = OUTPUT_TMP_DIR / "step4_cloud_run"
    with Diagram(
        "Step 6: Cloud Run Multi-Container Pod [SERVERLESS 🚀]",
        filename=str(f4_path),
        show=False,
        direction="LR",
        graph_attr=GRAPH_ATTRS,
        node_attr=NODE_ATTRS,
        edge_attr=EDGE_ATTRS,
        outformat="png",
    ):
        users = Users("Web & Mobile Users")
        with Cluster("Google Cloud Ingress"):
            lb = LoadBalancing("Cloud Load Balancing")

        with Cluster("Cloud Run Multi-Container Pod"):
            web = Run("Puma Web (Rails 8)")
            worker = Run("Solid Queue Worker")
            proxy = Run("Cloud SQL Proxy (Sidecar)")

        with Cluster("Google Cloud Persistence"):
            db = SQL("Cloud SQL PostgreSQL")
            gcs = Storage("Google Cloud Storage")

        with Cluster("Google Cloud Security"):
            sm = SecretManager("Secret Manager")

        users >> lb >> web
        web >> Edge(label="Enqueue Jobs", style="dashed") >> worker
        web >> proxy
        worker >> proxy
        proxy >> Edge(label="mTLS Tunnel", color="#188038") >> db
        web >> gcs
        worker >> gcs
        sm >> Edge(label="Runtime Secrets", style="dotted", color="#d93025") >> web
        sm >> Edge(style="dotted", color="#d93025") >> worker

    frames.append(OUTPUT_TMP_DIR / "step4_cloud_run.png")

    # Frame 5: Canonical Production Architecture (Full GCP Blueprint)
    # Ensure canonical is generated
    generate_canonical()
    frames.append(OUTPUT_TMP_DIR / "arch_diagram.png")

    print(f"🎬 Compiling {len(frames)} photograms into animated GIF...")

    # Load and normalize all frames to a uniform canvas size with white background
    images = [Image.open(f).convert("RGBA") for f in frames]
    max_w = max(img.width for img in images)
    max_h = max(img.height for img in images)

    canvas_w = max(max_w + 80, 1600)
    canvas_h = max(max_h + 80, 900)

    processed_frames = []
    for img in images:
        canvas = Image.new("RGB", (canvas_w, canvas_h), (255, 255, 255))
        offset_x = (canvas_w - img.width) // 2
        offset_y = (canvas_h - img.height) // 2
        canvas.paste(img, (offset_x, offset_y), mask=img.split()[3])
        processed_frames.append(canvas)

    gif_repo = ASSETS_DIR / "arch_evolution.gif"
    gif_workshop = WORKSHOP_IMAGES_DIR / "arch_evolution.gif"

    # 1800ms per frame, loop indefinitely
    processed_frames[0].save(
        gif_repo,
        save_all=True,
        append_images=processed_frames[1:],
        duration=1800,
        loop=0,
        optimize=True,
    )
    shutil.copyfile(gif_repo, gif_workshop)
    print(f"🎉 Animated GIF successfully compiled:\n   - {gif_repo}\n   - {gif_workshop}")


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

    if args.evolution or args.all:
        generate_evolution()

    return 0


if __name__ == "__main__":
    sys.exit(main())
