# Implementation Plan: Deterministic GCP Architecture Diagram & Evolution GIF (Issue #66)

## Phase 1: Environment & Tooling Setup (TDD Red-Green)
- [x] Task: Write failing unit test `test/test_architecture_diagram.rb` checking for diagram outputs (cc7103b)
- [x] Task: Scaffold `diagrams/` with `pyproject.toml` via `uv` (`diagrams`, `pillow`) (204ac68)
- [x] Task: Add `just diagram`, `just diagram-evolution`, and `just diagrams` recipes to root `justfile` (3e1ecc9)
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md) (Phase 1 Complete)

## Phase 2: Canonical GCP Architecture Diagram Implementation
- [ ] Task: Implement canonical multi-container Cloud Run architecture in `diagrams/generate_diagrams.py` featuring ALL GCP services and official GCP icons
- [ ] Task: Render high-resolution `arch_diagram.png` to `assets/` and `workshop/assets/images/`
- [ ] Task: Verify test `test/test_architecture_diagram.rb` passes for canonical diagram
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 3: Progressive Evolution Frames & Animated GIF
- [ ] Task: Implement milestone frame generators (Local SQLite -> Cloud SQL -> GCS -> Cloud Run -> Vertex AI) in `diagrams/generate_diagrams.py`
- [ ] Task: Assemble evolution frames into looping `arch_evolution.gif` using Pillow
- [ ] Task: Output `assets/arch_evolution.gif` and `workshop/assets/images/arch_evolution.gif`
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 4: Workshop & Presentation Slides Integration
- [ ] Task: Embed diagram and GIF in `workshop/CODELAB.md` (Page 1) and synchronize with `workshop/SKELETON.md`
- [ ] Task: Add architecture diagram slide to `slides/index.md` and compile with `just build-slides`
- [ ] Task: Run `build_ghpages.rb` and full test suites (`just test`, `just test-slides`, `ruby test/test_architecture_diagram.rb`)
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)
