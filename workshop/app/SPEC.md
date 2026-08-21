# Codelab Visualizer - Specification (SPEC.md)

This document contains the functional specifications, design decisions, and implementation details for the Codelab Visualizer, a lightweight, hot-reloading server designed to render multi-page markdown-based workshops (like `CODELAB.md` or `WORKSHOP.md`) in a responsive Google Codelab-like interface.

---

## 1. Functional Requirements

### 1.1 Page Separation and Routing
*   **Separation by H2:** The Markdown document's H2 headers (`## Title`) act as page/step separators.
*   **Page 0/Welcome:** The content before the first H2 is treated as "Overview" or "Welcome" if it contains non-empty text, otherwise it is discarded, and Step 0 starts with the first H2.
*   **Client-Side Navigation:** Steps are served as a single HTML page containing all step elements, shown/hidden using standard client-side URL hashes (`#0`, `#1`, ..., `#n`).
*   **Fallback Handling:** If a non-existent step is requested (e.g. `#123`), the visualizer defaults back to step 0 (`#0`).

### 1.2 User Interface & Layout
*   **Split Layout:**
    *   **Sidebar (Left):** Circular-numbered list of steps. Highlights the active step and marks preceding steps as "completed" (green circle).
    *   **Header (Top):** Displays Codelab title, active step name, and optional frontmatter metadata (author, total duration).
    *   **Main Container (Center):** Shows active step markdown content rendered into HTML.
    *   **Footer (Bottom):** Fixed navigation containing a `Back` button (hidden on page 0), `Next` (or `Restart` on last page) button, and progress indicator (`Step X of Y`).
*   **Glassmorphism & styling:** Semi-transparent backdrops (`backdrop-filter: blur()`), elegant border shadows, and modern Google-like typography.
*   **Code Highlighting:** Integrated Prism.js styling via CDN with support for Ruby, Bash, YAML, and Terraform code block formatting.

### 1.3 Static Asset and Image Handling
*   **Asset Routing:** The server supports a catch-all route for static assets (e.g. images, stylesheets).
*   **Relative Path Lookup:** Assets are resolved relative to the markdown file's parent directory, and fall back to the git root directory, ensuring relative image markdown tags (e.g. `![Pic](images/pic.png)`) work out-of-the-box.

### 1.4 A2UI Protocol Support
*   **JSON Endpoint:** The server exposes `/a2ui` to serve a structured representation of the Codelab steps conforming to the A2UI (Agent-to-User Interface) protocol draft, enabling automated agents or host applications to consume the visualizer data programmatically.

---

## 2. Technical Stack

*   **Language:** Ruby 3.3+
*   **Framework:** Sinatra 4.2+ (Modular Application `Sinatra::Base`)
*   **Markdown Renderer:** Kramdown 2.5+ with `kramdown-parser-gfm`
*   **Server:** Puma 8.0+
*   **Assets:** CDN-loaded Prism.js, Google Fonts (`Google Sans`, `Roboto`)

---

## 3. Configuration & CLI Usage

The visualizer supports the following command-line interface:
```bash
./server.rb [options] [path_to_markdown_file]
```

### Options:
*   `-p, --port PORT`: Specifies port (default: `8080` for main development).
*   `-b, --bind BIND`: Specifies IP address (default: `localhost`).
*   `-h, --help`: Prints available options.

---

## 4. Current Implementation Status

- [x] Initial Sinatra server boot configuration.
- [x] Kramdown with GFM parsing logic.
- [x] Client-side CSS and layout mimicking Google Codelabs.
- [x] Relative static assets serving logic from project and git root.
- [x] Added `just workshop-dev` entrypoint in root `justfile`.
- [x] Resilient auto-installation for missing gems inside user workspace (`~/.local/share/gem/ruby`).
- [x] Implement a full A2UI-JSON endpoint `/a2ui`.
- [x] Style polish with nice transparencies & custom A2UI-inspired card elements.
- [x] Added sample visual assets (GCP Ruby logo and NanoBanana mascot) under `assets/images/` and linked them in `CODELAB.md` to verify relative image path serving.

