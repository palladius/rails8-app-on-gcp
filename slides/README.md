# 📊 Workshop Kickoff Slides (Marp)

This folder contains the introductory presentation deck for the **Rails 8 on Google Cloud** workshop.

It is authored in Markdown and rendered using [Marp (Markdown Presentation Ecosystem)](https://marp.app/).

---

## 🚀 Quick Start

### Run the live presentation server

From the repository root:

```bash
just slides
```

This launches the Marp server at **`http://localhost:8082`**. Open this URL in any browser to present or navigate through the slides.

To run on a custom port:

```bash
just slides 8888
```

---

## 🛠️ Build Static HTML / PDF

To compile static slides:

```bash
just build-slides
```

This outputs `slides/dist/index.html`.

To export as PDF (requires Chrome / Chromium installed):

```bash
marp slides/index.md --pdf -o slides/dist/slides.pdf
```

---

## 📑 Slide Outline

1. **Welcome & Kickoff**: Intro by Riccardo & Emiliano.
2. **Download & Install Antigravity**: Cross-platform binaries.
3. **Launch & Connect**: Sign in with Google identity.
4. **Reclaim Credits Now**: Redeem Google Cloud credits voucher for hands-on GCP projects.
5. **Set the Mission**: Launch prompt pointing Antigravity to `workshop/landing-page/README.md`.
6. **The Pedagogical Contract**: Socratic tutoring ("Guide me, don't do everything for me").
