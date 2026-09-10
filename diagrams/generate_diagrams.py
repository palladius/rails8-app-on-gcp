#!/usr/bin/env python3
"""Deterministic Google Cloud Architecture Diagram Generator for Rails 8 on GCP.

Generates:
1. Canonical production reference architecture diagram (arch_diagram.png),
   highlighting exclusively REAL BILLABLE Google Cloud products with a single
   Cloud Run service icon and 3 compact stacked sub-containers in monospace (tt)
   with emoji icons.
2. Progressive evolutionary frames and animated GIF (arch_evolution.gif).
"""

import argparse
import os
import shutil
import sys
from pathlib import Path

from diagrams import Diagram, Cluster, Edge, Node
from diagrams.gcp.compute import Run
from diagrams.gcp.database import SQL
from diagrams.gcp.storage import Storage
from diagrams.gcp.security import SecretManager
from diagrams.gcp.ml import VertexAI
from diagrams.gcp.devtools import Build, ContainerRegistry
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
    """Generates the canonical production GCP architecture diagram highlighting real billable GCP objects."""
    print("🎨 Generating Canonical Google Cloud Architecture Diagram (Compact 3-Row Matrioskas & Billable GCP Objects)...")
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

        with Cluster("Google Cloud Run (1. Billable Serverless Service)"):
            cloud_run = Run("Cloud Run Service\n(Serverless Pod)")
            with Cluster("Pod Containers (In-Pod localhost)"):
                web = Node("🌐 puma (web :8080)", shape="box", style="rounded,filled", fillcolor="#e8f0fe", fontname="Courier", fontsize="11", height="0.35")
                worker = Node("⚡ solid_queue (worker)", shape="box", style="rounded,filled", fillcolor="#fef7e0", fontname="Courier", fontsize="11", height="0.35")
                proxy = Node("🔒 cloud_sql_proxy (sidecar)", shape="box", style="rounded,filled", fillcolor="#e6f4ea", fontname="Courier", fontsize="11", height="0.35")
                web - Edge(style="invis") - worker - Edge(style="invis") - proxy

        with Cluster("Google Cloud Managed Persistence (Billable)"):
            db = SQL("Cloud SQL PostgreSQL\n(2. Managed DB Instance)")
            gcs = Storage("Google Cloud Storage\n(3. Private Media Bucket)")

        sm = SecretManager("Secret Manager\n(4. Runtime Secrets)")
        vertex = VertexAI("Vertex AI\n(5. Nano Banana & Gemini)")

        with Cluster("DevOps & CI/CD Pipeline (Billable)"):
            cb = Build("Cloud Build\n(6. CI/CD Pipeline)")
            ar = ContainerRegistry("Artifact Registry\n(7. OCI Containers)")

        # Ingress traffic
        users >> Edge(label="HTTPS Ingress", color="#1a73e8", style="bold") >> cloud_run
        cloud_run >> Edge(label="Port 8080", color="#1a73e8") >> web

        # In-pod async job delegation
        web >> Edge(label="Enqueue Jobs (Solid Queue DB)", color="#f9ab00", style="dashed") >> worker

        # Database connections via localhost Cloud SQL proxy
        web >> Edge(label="localhost:5432", color="#188038") >> proxy
        worker >> Edge(label="localhost:5432", color="#188038") >> proxy
        proxy >> Edge(label="mTLS Encrypted Tunnel\n(No Public IP)", color="#188038", style="bold") >> db

        # Object Storage
        web >> Edge(label="ActiveStorage (Signed URLs)", color="#4285F4") >> gcs
        worker >> Edge(label="Direct Blob Attach", color="#4285F4") >> gcs

        # Secret injection
        sm >> Edge(label="Runtime Secret Injection", color="#d93025", style="dotted") >> cloud_run

        # GenAI Async Pipeline
        worker >> Edge(label="Nano Banana Imagen 3\n& Audio Summaries", color="#a142f4", style="bold") >> vertex

        # CI/CD deployment
        cb >> Edge(label="Build Containers") >> ar >> Edge(label="Deploy Revision") >> cloud_run

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
            web = Node("🌐 puma (web :3000)", shape="box", style="rounded,filled", fillcolor="#e8f0fe", fontname="Courier", fontsize="11", height="0.35")
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
            web = Node("🌐 puma (web :3000)", shape="box", style="rounded,filled", fillcolor="#e8f0fe", fontname="Courier", fontsize="11", height="0.35")
            proxy = Node("🔒 cloud_sql_proxy (localhost:5432)", shape="box", style="rounded,filled", fillcolor="#e6f4ea", fontname="Courier", fontsize="11", height="0.35")
            disk = GenericStorage("Local Disk Storage\n(Ephemeral Uploads)")
            web - Edge(style="invis") - proxy

        with Cluster("Google Cloud Managed Persistence (Billable)"):
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
            web = Node("🌐 puma (web :3000)", shape="box", style="rounded,filled", fillcolor="#e8f0fe", fontname="Courier", fontsize="11", height="0.35")
            proxy = Node("🔒 cloud_sql_proxy (localhost:5432)", shape="box", style="rounded,filled", fillcolor="#e6f4ea", fontname="Courier", fontsize="11", height="0.35")
            web - Edge(style="invis") - proxy

        with Cluster("Google Cloud Managed Persistence (Billable)"):
            db = SQL("Cloud SQL PostgreSQL\n(Managed Instance)")
            gcs = Storage("Google Cloud Storage\n(Private Bucket)")

        dev >> Edge(label="HTTP :3000") >> web
        web >> Edge(label="localhost:5432") >> proxy
        proxy >> Edge(label="mTLS Tunnel", color="#188038") >> db
        web >> Edge(label="ActiveStorage (Signed URLs)", color="#4285F4") >> gcs

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

        with Cluster("Google Cloud Run (Billable Serverless Service)"):
            cloud_run = Run("Cloud Run Service")
            with Cluster("Pod Containers"):
                web = Node("🌐 puma (web :8080)", shape="box", style="rounded,filled", fillcolor="#e8f0fe", fontname="Courier", fontsize="11", height="0.35")
                worker = Node("⚡ solid_queue (worker)", shape="box", style="rounded,filled", fillcolor="#fef7e0", fontname="Courier", fontsize="11", height="0.35")
                proxy = Node("🔒 cloud_sql_proxy (sidecar)", shape="box", style="rounded,filled", fillcolor="#e6f4ea", fontname="Courier", fontsize="11", height="0.35")
                web - Edge(style="invis") - worker - Edge(style="invis") - proxy

        with Cluster("Google Cloud Persistence (Billable)"):
            db = SQL("Cloud SQL PostgreSQL")
            gcs = Storage("Google Cloud Storage")

        sm = SecretManager("Secret Manager\n(Runtime Secrets)")

        users >> Edge(label="HTTPS") >> cloud_run >> web
        web >> Edge(label="Enqueue Jobs", style="dashed") >> worker
        web >> proxy
        worker >> proxy
        proxy >> Edge(label="mTLS Tunnel", color="#188038") >> db
        web >> gcs
        worker >> gcs
        sm >> Edge(label="Runtime Secrets", style="dotted", color="#d93025") >> cloud_run

    frames.append(OUTPUT_TMP_DIR / "step4_cloud_run.png")

    # Frame 5: Canonical Production Architecture (Full Billable GCP Blueprint)
    generate_canonical()
    frames.append(OUTPUT_TMP_DIR / "arch_diagram.png")

    print(f"🎬 Compiling {len(frames)} photograms into animated GIF...")

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
