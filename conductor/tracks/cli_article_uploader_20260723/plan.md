# Implementation Plan: CLI Article Uploader (`bin/new_article.rb`)

## Phase 1: Setup and Basic Script Parsing [checkpoint: 86abf8e]
- [x] Task: Create `bin/new_article.rb` executable script wrapper for Rails runner. [86abf8e]
    - [x] Initialize `OptionParser` to parse `--article` and `--image` flags.
    - [x] Add support for reading from `-` (stdin) or a file path for the `--article` flag.
    - [x] Validate that `--article` is provided and abort with usage instructions if missing.
- [x] Task: Write Tests (Red Phase) [4302bd3]
    - [x] Add an integration test or mock unit test simulating execution of the CLI script with basic arguments.
- [x] Task: Implement to Pass Tests (Green Phase) [86abf8e]
    - [x] Implement the `OptionParser` logic and stdin/file reading logic.
- [x] Task: Conductor - User Manual Verification 'Phase 1: Setup and Basic Script Parsing' (Protocol in workflow.md)

## Phase 2: Metadata Extraction [checkpoint: 86abf8e]
- [x] Task: Write Tests (Red Phase) [4302bd3]
    - [x] Write tests verifying that a Markdown heading (`# Title`) is correctly extracted as the title.
    - [x] Write tests verifying that the fallback uses the basename of the file when no heading exists.
    - [x] Write tests verifying the fallback for `stdin` uses a default string like "Untitled Article".
- [x] Task: Implement to Pass Tests (Green Phase) [86abf8e]
    - [x] Implement regex or line-by-line parsing to extract the H1 title.
    - [x] Implement the filename fallback logic.
- [x] Task: Conductor - User Manual Verification 'Phase 2: Metadata Extraction' (Protocol in workflow.md)

## Phase 3: Post Creation and Image Attachment [checkpoint: 4302bd3]
- [x] Task: Write Tests (Red Phase) [4302bd3]
    - [x] Write tests ensuring a `Post` is created with the parsed title and body.
    - [x] Write tests verifying that an existing `--image` path successfully attaches a `cover_image`.
    - [x] Write tests verifying that a non-existent `--image` path skips the attachment and logs a warning to `stderr`.
- [x] Task: Implement to Pass Tests (Green Phase) [86abf8e]
    - [x] Use ActiveRecord to create the `Post`.
    - [x] Handle the `cover_image` attachment logic using `File.open`.
    - [x] Rescue `Errno::ENOENT` when attaching the image to output the warning to `stderr`.
- [x] Task: Conductor - User Manual Verification 'Phase 3: Post Creation and Image Attachment' (Protocol in workflow.md)
