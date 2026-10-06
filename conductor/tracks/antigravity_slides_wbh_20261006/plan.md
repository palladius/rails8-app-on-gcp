# Implementation Plan: Antigravity-Centric Workshop Kickoff Slides (EN/IT) & Wednesday Build Hour Deck

## Phase 1: TDD & Dual-Language Antigravity Slide Decks (`slides/antigravity.en.md` & `slides/antigravity.it.md`)
- [ ] Task: Extend `test/test_slides.rb` with failing tests for the new Antigravity EN/IT decks (Red Phase)
    - [ ] Verify `slides/antigravity.en.md` and `slides/antigravity.it.md` exist and contain valid Marp frontmatter (`marp: true`, `theme: gaia`, `paginate: true`).
    - [ ] Verify all 5+ Antigravity onboarding steps and all 3 copyable prompts (`git clone` to `Documents` + sound, Codelab + `landing-page/README` prompt, and post-coupon GCP project creation prompt) are present in both decks.
    - [ ] Verify Windows WSL tip, Turbo Mode instructions + screenshot placeholder, and Page 2 Codelab Green Button instructions are present.
    - [ ] Verify both decks compile to `slides/dist/antigravity.en.html` and `slides/dist/antigravity.it.html` with zero escaped HTML tags (`<code>&lt;div...`) and all external links using `target="_blank" rel="noopener noreferrer"`.
- [ ] Task: Create `slides/antigravity.en.md` (English / Wednesday Build Hour edition) and `slides/antigravity.it.md` (Italian / DevFest Modena edition) (Green Phase)
    - [ ] Author `slides/antigravity.en.md` with language switcher link to `antigravity.it.html`, all 3 copyable prompts (`📋 Copy Prompt`), Turbo Mode callout & screenshot box, Page 2 Codelab credits (`#1`), canonical architecture diagram, and Workshop Anthem.
    - [ ] Author `slides/antigravity.it.md` with Italian localization, language switcher link to `antigravity.en.html`, all 3 Italian copyable prompts (`📋 Copy Prompt`), Turbo Mode callout & screenshot box, Page 2 Codelab credits (`?hl=it#1`), canonical architecture diagram, and Workshop Anthem.
- [ ] Task: Update `justfile`, `slides/README.md`, and `workshop/visualizer/build_ghpages.rb` to build and publish both decks
    - [ ] Update `build-slides` in `justfile` to compile `slides/antigravity.en.md` -> `slides/dist/antigravity.en.html` and `slides/antigravity.it.md` -> `slides/dist/antigravity.it.html`, and add `slides-antigravity` convenience recipe.
    - [ ] Update `workshop/visualizer/build_ghpages.rb` to copy `antigravity.en.html` and `antigravity.it.html` into `workshop/build/slides/`.
    - [ ] Document the new decks in `slides/README.md`.
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 2: Wednesday Build Hour Event Registration, Release Hygiene & Localhost Preview
- [ ] Task: Register the Wednesday Build Hour event under `workshop/events/20261007-wednesday-build-hour/`
    - [ ] Create `workshop/events/20261007-wednesday-build-hour/README.md` with event date (Wed 7 Oct 2026, 13:00-14:00 CEST), GDG Community Dev virtual URL, and links to the English/Italian Antigravity slide decks and Codelab.
    - [ ] Update `workshop/events/README.md` to list the 2026-10-07 Wednesday Build Hour event.
- [ ] Task: Run full test suite (`just test` & `just test-slides`), update `VERSION` and `CHANGELOG.md`, and serve slides on `localhost`
    - [ ] Run `just build-slides`, `just test-slides`, and `just test`.
    - [ ] Bump `VERSION` and document the new Antigravity EN/IT decks and Wednesday Build Hour event in `CHANGELOG.md`.
    - [ ] Start the local slide presentation server and share the clickable `localhost` URLs for both `.en` and `.it` decks with Riccardo.
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)
