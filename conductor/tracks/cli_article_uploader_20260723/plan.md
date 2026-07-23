# Implementation Plan: CLI Article Uploader (`bin/new_article.rb`)

## Phase 1: Setup and Basic Script Parsing
- [ ] Task: Create `bin/new_article.rb` executable script wrapper for Rails runner.
    - [ ] Initialize `OptionParser` to parse `--article` and `--image` flags.
    - [ ] Add support for reading from `-` (stdin) or a file path for the `--article` flag.
    - [ ] Validate that `--article` is provided and abort with usage instructions if missing.
- [ ] Task: Write Tests (Red Phase)
    - [ ] Add an integration test or mock unit test simulating execution of the CLI script with basic arguments.
- [ ] Task: Implement to Pass Tests (Green Phase)
    - [ ] Implement the `OptionParser` logic and stdin/file reading logic.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Setup and Basic Script Parsing' (Protocol in workflow.md)

## Phase 2: Metadata Extraction
- [ ] Task: Write Tests (Red Phase)
    - [ ] Write tests verifying that a Markdown heading (`# Title`) is correctly extracted as the title.
    - [ ] Write tests verifying that the fallback uses the basename of the file when no heading exists.
    - [ ] Write tests verifying the fallback for `stdin` uses a default string like "Untitled Article".
- [ ] Task: Implement to Pass Tests (Green Phase)
    - [ ] Implement regex or line-by-line parsing to extract the H1 title.
    - [ ] Implement the filename fallback logic.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Metadata Extraction' (Protocol in workflow.md)

## Phase 3: Post Creation and Image Attachment
- [ ] Task: Write Tests (Red Phase)
    - [ ] Write tests ensuring a `Post` is created with the parsed title and body.
    - [ ] Write tests verifying that an existing `--image` path successfully attaches a `cover_image`.
    - [ ] Write tests verifying that a non-existent `--image` path skips the attachment and logs a warning to `stderr`.
- [ ] Task: Implement to Pass Tests (Green Phase)
    - [ ] Use ActiveRecord to create the `Post`.
    - [ ] Handle the `cover_image` attachment logic using `File.open`.
    - [ ] Rescue `Errno::ENOENT` when attaching the image to output the warning to `stderr`.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Post Creation and Image Attachment' (Protocol in workflow.md)
