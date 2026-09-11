#!/usr/bin/env python3
"""Deterministic Google Cloud Architecture Diagram Generator for Rails 8 on GCP.

Generates:
1. Canonical production reference architecture diagram (arch_diagram.png),
   highlighting exclusively REAL BILLABLE Google Cloud products with a single
   Cloud Run service icon and a compact 3-row matrioska container table
   in monospace (tt) with emojis (strictly stacked vertically).
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
    "nodesep": "0.8",
    "ranksep": "1.3",
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


ASSETS_ICONS_DIR = ASSETS_DIR / "icons"


def get_icon_paths():
    """Returns paths to 14px Rails and Solid Queue icons, generating or verifying them."""
    ASSETS_ICONS_DIR.mkdir(parents=True, exist_ok=True)
    rails_path = ASSETS_ICONS_DIR / "rails_14.png"
    queue_path = ASSETS_ICONS_DIR / "solid_queue_14.png"

    if not rails_path.exists():
        import diagrams.programming.framework as df
        src_rails = Path(df.__file__).parent.parent.parent / "resources" / "programming" / "framework" / "rails.png"
        if src_rails.exists():
            img = Image.open(src_rails).convert("RGBA")
            img.resize((14, 14), Image.Resampling.LANCZOS).save(rails_path)

    return str(rails_path.resolve()), str(queue_path.resolve())


def get_containers_table_html(rails_icon: str, queue_icon: str) -> str:
    return f"""<
<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" CELLPADDING="6" BGCOLOR="#FFFFFF" COLOR="#4285F4" STYLE="ROUNDED">
  <TR>
    <TD PORT="in" BGCOLOR="#E8F0FE" ALIGN="RIGHT"><FONT FACE="Courier" POINT-SIZE="11"><B>8080</B> </FONT></TD>
    <TD BGCOLOR="#E8F0FE" ALIGN="CENTER"><IMG SRC="{rails_icon}"/></TD>
    <TD PORT="rails" BGCOLOR="#E8F0FE" ALIGN="LEFT"><FONT FACE="Courier" POINT-SIZE="11"> <B>rails_app</B> <I>(puma)</I></FONT></TD>
  </TR>
  <TR>
    <TD BGCOLOR="#E6F4EA" ALIGN="RIGHT"><FONT FACE="Courier" POINT-SIZE="11"><B>5432</B> </FONT></TD>
    <TD BGCOLOR="#E6F4EA" ALIGN="CENTER"><FONT POINT-SIZE="11">🔒</FONT></TD>
    <TD PORT="proxy" BGCOLOR="#E6F4EA" ALIGN="LEFT"><FONT FACE="Courier" POINT-SIZE="11"> <B>cloud_sql_proxy</B> <I>(sidecar)</I></FONT></TD>
  </TR>
  <TR>
    <TD BGCOLOR="#FEF7E0" ALIGN="RIGHT"><FONT FACE="Courier" POINT-SIZE="11"><B>----</B> </FONT></TD>
    <TD BGCOLOR="#FEF7E0" ALIGN="CENTER"><IMG SRC="{queue_icon}"/></TD>
    <TD PORT="worker" BGCOLOR="#FEF7E0" ALIGN="LEFT"><FONT FACE="Courier" POINT-SIZE="11"> <B>solid_queue</B> <I>(worker)</I></FONT></TD>
  </TR>
</TABLE>>"""


def generate_canonical():
    """Generates the canonical production GCP architecture diagram highlighting real billable GCP objects."""
    print("🎨 Generating Canonical Google Cloud Architecture Diagram (Compact 3-Row Matrioskas & Billable GCP Objects)...")
    out_filename = OUTPUT_TMP_DIR / "arch_diagram"
    rails_icon, queue_icon = get_icon_paths()
    containers_table = get_containers_table_html(rails_icon, queue_icon)

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
        users = Users("Web Users")

        with Cluster("Google Cloud Run"):
            cloud_run = Run("S1. Cloud Run")
            containers = Node(label=containers_table, shape="none", fixedsize="false")
            cloud_run - Edge(style="invis") - containers

        with Cluster("Google Cloud Persistence"):
            db = SQL("S2. Cloud SQL - pgsql")
            gcs = Storage("S3. Cloud Storage")

        sm = SecretManager("S4. Secret Manager")
        vertex = VertexAI("S5. Vertex AI")

        with Cluster("DevOps & CI/CD"):
            cb = Build("S6. Cloud Build")
            ar = ContainerRegistry("S7. Artifact Registry")

        # Ingress traffic
        users >> Edge(label="HTTPS", color="#1a73e8", style="bold") >> cloud_run

        # Database connections via localhost Cloud SQL proxy
        containers >> Edge(label="mTLS Tunnel", color="#188038", style="bold", tailport="proxy:e", minlen="2") >> db

        # Object Storage
        containers >> Edge(label="ActiveStorage", color="#4285F4", tailport="rails:e", minlen="2") >> gcs

        # Secret injection
        sm >> Edge(label="Secrets", color="#d93025", style="dotted") >> cloud_run

        # GenAI Async Pipeline
        containers >> Edge(label="GenAI Pipeline", color="#a142f4", style="bold", tailport="worker:e", minlen="2") >> vertex

        # CI/CD deployment
        cb >> Edge(label="Build") >> ar >> Edge(label="Deploy") >> cloud_run

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
    rails_icon, queue_icon = get_icon_paths()
    containers_table = get_containers_table_html(rails_icon, queue_icon)
    frames = []

    # Frame 1: Local / Ephemeral Baseline
    f1_path = OUTPUT_TMP_DIR / "step1_local_baseline"
    f1_table = """<
<TABLE BORDER="1" CELLBORDER="1" CELLSPACING="0" CELLPADDING="7" BGCOLOR="#FFFFFF" COLOR="#DADCE0" STYLE="ROUNDED">
  <TR><TD BGCOLOR="#E8F0FE" ALIGN="LEFT"><FONT FACE="Courier" POINT-SIZE="11"><B>🌐 rails_app</B> (puma :3000)</FONT></TD></TR>
  <TR><TD BGCOLOR="#F1F3F4" ALIGN="LEFT"><FONT FACE="Courier" POINT-SIZE="11"><B>🗄️ local_sqlite</B> (ephemeral disk)</FONT></TD></TR>
  <TR><TD BGCOLOR="#F1F3F4" ALIGN="LEFT"><FONT FACE="Courier" POINT-SIZE="11"><B>📁 local_storage</B> (public/uploads)</FONT></TD></TR>
</TABLE>>"""

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
            local_stack = Node(label=f1_table, shape="none")

        dev >> Edge(label="HTTP :3000") >> local_stack

    frames.append(OUTPUT_TMP_DIR / "step1_local_baseline.png")

    # Frame 2: Google Cloud SQL
    f2_path = OUTPUT_TMP_DIR / "step2_cloud_sql"
    f2_table = """<
<TABLE BORDER="1" CELLBORDER="1" CELLSPACING="0" CELLPADDING="7" BGCOLOR="#FFFFFF" COLOR="#DADCE0" STYLE="ROUNDED">
  <TR><TD PORT="proxy" BGCOLOR="#E6F4EA" ALIGN="LEFT"><FONT FACE="Courier" POINT-SIZE="11"><B>🔒 cloud_sql_proxy</B> (localhost:5432)</FONT></TD></TR>
  <TR><TD PORT="rails" BGCOLOR="#E8F0FE" ALIGN="LEFT"><FONT FACE="Courier" POINT-SIZE="11"><B>🌐 rails_app</B> (puma :3000)</FONT></TD></TR>
  <TR><TD PORT="storage" BGCOLOR="#F1F3F4" ALIGN="LEFT"><FONT FACE="Courier" POINT-SIZE="11"><B>📁 local_storage</B> (ephemeral uploads)</FONT></TD></TR>
</TABLE>>"""

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
            local_stack = Node(label=f2_table, shape="none")

        with Cluster("Google Cloud Persistence"):
            db = SQL("S2. Cloud SQL - pgsql")

        dev >> Edge(label="HTTP :3000") >> local_stack
        local_stack >> Edge(label="mTLS Tunnel", color="#188038", style="bold", tailport="proxy:e") >> db

    frames.append(OUTPUT_TMP_DIR / "step2_cloud_sql.png")

    # Frame 3: Private GCS with IAM signed URLs
    f3_path = OUTPUT_TMP_DIR / "step3_cloud_storage"
    f3_table = """<
<TABLE BORDER="1" CELLBORDER="1" CELLSPACING="0" CELLPADDING="7" BGCOLOR="#FFFFFF" COLOR="#DADCE0" STYLE="ROUNDED">
  <TR><TD PORT="proxy" BGCOLOR="#E6F4EA" ALIGN="LEFT"><FONT FACE="Courier" POINT-SIZE="11"><B>🔒 cloud_sql_proxy</B> (localhost:5432)</FONT></TD></TR>
  <TR><TD PORT="rails" BGCOLOR="#E8F0FE" ALIGN="LEFT"><FONT FACE="Courier" POINT-SIZE="11"><B>🌐 rails_app</B> (puma :3000)</FONT></TD></TR>
</TABLE>>"""

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
            local_stack = Node(label=f3_table, shape="none")

        with Cluster("Google Cloud Persistence"):
            db = SQL("S2. Cloud SQL - pgsql")
            gcs = Storage("S3. Cloud Storage")

        dev >> Edge(label="HTTP :3000") >> local_stack
        local_stack >> Edge(label="mTLS Tunnel", color="#188038", tailport="proxy:e") >> db
        local_stack >> Edge(label="ActiveStorage (Signed URLs)", color="#4285F4", tailport="rails:e") >> gcs

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
        users = Users("Web Users")

        with Cluster("Google Cloud Run"):
            cloud_run = Run("S1. Cloud Run")
            containers = Node(label=containers_table, shape="none", fixedsize="false")
            cloud_run - Edge(style="invis") - containers

        with Cluster("Google Cloud Persistence"):
            db = SQL("S2. Cloud SQL - pgsql")
            gcs = Storage("S3. Cloud Storage")

        sm = SecretManager("S4. Secret Manager")

        users >> Edge(label="HTTPS", color="#1a73e8", style="bold") >> cloud_run
        containers >> Edge(label="mTLS Tunnel", color="#188038", tailport="proxy:e") >> db
        containers >> Edge(label="ActiveStorage", color="#4285F4", tailport="rails:e") >> gcs
        sm >> Edge(label="Secrets", style="dotted", color="#d93025") >> cloud_run

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
