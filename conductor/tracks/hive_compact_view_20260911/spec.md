# Specification: Workshop Hive Leaderboard High-Density 50+ Compact View

## Overview
In workshop and conference room settings with 50+ attendees, instructors need to monitor all students on a single screen without scrolling. Currently, Hive student rows wrap stack metrics and Cloud Run URLs onto multiple lines, fitting only ~15-20 students in a standard 1080p viewport.
This feature introduces a **High-Density Compact Mode** for `workshop/hive` that guarantees every student row is rendered strictly on a single horizontal line, paired with a header toggle button, URL parameter support (`?compact=true`), and `localStorage` persistence.

## Functional Requirements
1. **Activation & Persistence**:
   - Support URL query parameter: `?compact=true` (also accepts `?compact=1` or `?density=compact`).
   - Add a high-visibility toggle button in the Hive UI header toolbar (e.g., `📐 View: Compact (50+)` / `Expanded`).
   - Sync toggle changes to the URL (`window.history.replaceState`) and persist the preference in `localStorage`.
2. **Strict Single-Line Student Rows**:
   - Every student entry rendered in a single, rigid row (`whitespace-nowrap`, compact height `py-1` / `h-7`, text size `text-xs`/`text-[11px]`):
     - **Status Dot & Latency**: `🟢 46ms` / `🔴 ERR` inline.
     - **Submission Time**: `HH:MM` format (e.g. `11:45`).
     - **Student Nickname**: Truncated with ellipsis (`max-w-[130px] truncate`), with full name on hover and trophy/medal if applicable.
     - **8-Segment Step Bar**: Fixed compact bar (`w-[80px] shrink-0`).
     - **Cloud Run App Link**: Direct link to the student's deployed Cloud Run service with Cloud Run icon.
     - **JSON Link**: Direct `{}` / `[JSON]` link to `/status.json`.
     - **Inline Stack Chips**: Ruby (e.g. `3.4.2`), Rails (e.g. `8.1.0`), and storage/DB chips inline on the same line without wrapping.
3. **Optimized Header & Podium**:
   - Reduce vertical margins and padding of the top stats banner and Step 8 Podium in compact mode to maximize the vertical table area for 50+ rows.
4. **Preserve Expanded View**:
   - When Compact Mode is toggled off, the leaderboard smoothly returns to the detailed multi-line expanded view.

## Non-Functional Requirements & Constraints
- **Zero Backend Repo Changes**: Absolute freeze on `workshop-rails8-hive-backend` (all work is strictly inside `workshop/hive/`).
- **Performance**: Instantaneous client-side re-rendering and polling updates with 50+ rows without layout shift.
- **Cross-Resolution**: Fits comfortably across 1080p, 1440p, and 4K displays.

## Acceptance Criteria
- [ ] `?compact=true` query parameter enables compact view on initial load.
- [ ] Header button toggles Compact/Expanded mode and persists in `localStorage`.
- [ ] Every student row is strictly 1 single line with no vertical wrapping or stacked cells.
- [ ] Displays status dot + ms, HH:MM, student nickname, 8-step bar, Cloud Run link, JSON link, and Ruby/Rails chips.
- [ ] Step 8 Podium and stats banner adopt low-profile compact styling when active.
- [ ] All existing Hive and Rails tests pass green.

## Out of Scope
- Backend database schema changes in `workshop-rails8-hive-backend`.
- Altering the upstream Google Sheets ingestion logic.
