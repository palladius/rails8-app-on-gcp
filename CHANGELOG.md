# Changelog

All notable changes to this project will be documented in this file.

## [0.1.2] - 2026-07-23
### Added
- 🎨 Post show page: glassmorphism card with hero image, styled title, meta line (updated at · comment count)
- 🔘 Post show actions: emoji buttons for Edit, Back, Destroy with confirmation dialog
- 👤 `User#display_name` helper (returns `name || email_address`)
- 🛣️ Added `/healthz` health-check route

### Fixed
- 🐛 Fix 500 error on `/posts/:id` — `simple_format` blew up on `ActionText::RichText` body; replaced with direct `<%= @post.body %>` rendering

### Changed
- 🧹 Flash notice on post show only renders when present (no empty `<p>` clutter)

## [0.1.1] - 2026-07-22
### Added
- 💎 Gemini-inspired blue-to-purple gradient background with glassmorphism UI
- 🔝 Sticky header nav bar with app logo, user badge (🧑‍💻 username), sign out
- 📊 Posts index: replaced ugly list with a clean table view
- ✏️❌ Inline action emojis (edit, delete with confirmation) per row
- 🦶 Footer with app name, version, Rails env, 📦 Code & 📖 Workshop links
- 🔗 Footer credits: "Made with [Ruby logo] love by Emiliano & Riccardo"
- ⚙️ Centralised app config (`config/initializers/app_config.rb`) for GitHub/Workshop URLs
- 🖼️ App logo (v1–v3) in header, linking to posts index

### Changed
- Posts table stripped to minimal `# | Title` — ID is clickable link to post
- Removed "New Post" from header nav (kept below table only)
- Removed Simple.css CDN (was conflicting with custom Gemini styles)
- Flash notice takes zero space when empty (conditional render)
- Eager loading for `cover_image` and `comments` to avoid N+1 queries

## [0.1.0] - 2026-07-21
### Added
- Initialized Conductor project workflow scaffolding.
- Defined Bifidus project vision (Rails 8 blueprint + Workshop).
- Updated `AGENTS.md` with explicit Google branding and incremental documentation instructions.
- Set up initial codebase framework in `blog/`.
