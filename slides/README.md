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

## 📑 Available Slide Decks

1. **Original Kickoff Deck (`slides/index.md` $\to$ `slides/dist/index.html`)**:
   - Original 6-slide DevFest Modena kickoff deck.
2. **Antigravity-Centric Kickoff Deck — English (`slides/antigravity.en.md` $\to$ `slides/dist/antigravity.en.html`)**:
   - Created for the **Wednesday Build Hour (WBH)** event and international workshops.
   - Step-by-step Antigravity 2.0 onboarding: Install (with WSL tip) $\to$ Gmail Login $\to$ Prompt 1 (`git clone` into `Documents` + audio chime) $\to$ Open New Project in Folder + Say `"ciao"` + Enable **Turbo Mode** (with 4 screenshots & PROD safety disclaimer) $\to$ Prompt 2 (Guided Codelab + `landing-page/README.md`) $\to$ Claim GCP Credits on Codelab Page 2 (`#1`) $\to$ Prompt 3 (Automated GCP Project Creation).
3. **Antigravity-Centric Kickoff Deck — Italian (`slides/antigravity.it.md` $\to$ `slides/dist/antigravity.it.html`)**:
   - Full Italian localization of the Antigravity-centric onboarding flow (`workshop-modena-YYYYMMDD`, `README.it.md`, Codelab `?hl=it#1`).
4. **Why Is This Workshop Different? (`slides/why-different.md` $\to$ `slides/dist/why-different.html`)**:
   - Deep-dive showcase deck on architectural highlights (Structured JSON Logging, etc.).

