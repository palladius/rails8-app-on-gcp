# Implementation Plan: Declarative Workshop Skeleton in YAML with Hybrid & LLM EVALs

## Phase 1: Skeleton YAML Architecture & Schema Definition
- [x] Task: Create `workshop/skeleton.yaml` with schema definition and full 8-step curriculum
  - [x] Define Steps 0 through 8 with `title`, `description`, `pseudocode`, `prerequisites`, `postrequisites`
  - [x] Add `evals` with mixed types: `shell`, `ruby`, and `llm` (with structured `{return, comment, error_message}` output)
- [x] Task: Phase Verification & Checkpoint (Validate YAML syntax and readability)

## Phase 2: Markdown Compiler (`build_skeleton.rb`)
- [x] Task: Implement `workshop/visualizer/build_skeleton.rb`
  - [x] Parse `workshop/skeleton.yaml` and render `workshop/SKELETON.md`
  - [x] Wire recipe into `justfile`: `just build-skeleton`
  - [x] Hook into `just build-ghpages`
- [x] Task: Phase Verification & Checkpoint (Verify generated SKELETON.md matches expected layout)

## Phase 3: Evaluation Engine (`bin/workshop_eval.rb`)
- [x] Task: Implement `bin/workshop_eval.rb`
  - [x] Add execution handler for `type: shell`
  - [x] Add execution handler for `type: ruby`
  - [x] Add execution handler for `type: llm` with structured JSON contract
  - [x] Add recipe to `justfile`: `just workshop-eval [step="all"]`
- [x] Task: Phase Verification & Checkpoint (Run `just workshop-eval 0` and verify green output)
