require "minitest/autorun"
require "open3"
require "fileutils"

class SlidesTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)
  SLIDES_MD = File.join(REPO_ROOT, "slides/index.md")
  AGY_EN_MD = File.join(REPO_ROOT, "slides/antigravity.en.md")
  AGY_IT_MD = File.join(REPO_ROOT, "slides/antigravity.it.md")
  ALL_SLIDE_SOURCES = Dir[File.join(REPO_ROOT, "slides/*.md")].reject { |f| File.basename(f) == "README.md" }.sort
  SLIDES_DIST_DIR = File.join(REPO_ROOT, "slides/dist")
  SLIDES_HTML = File.join(SLIDES_DIST_DIR, "index.html")
  AGY_EN_HTML = File.join(SLIDES_DIST_DIR, "antigravity.en.html")
  AGY_IT_HTML = File.join(SLIDES_DIST_DIR, "antigravity.it.html")

  def marp_cmd
    nvm_bins = Dir[File.expand_path("~/.nvm/versions/node/*/bin")].sort.reverse
    ENV["PATH"] = (nvm_bins + [ENV["PATH"]]).join(":") unless nvm_bins.empty?
    system("which marp > /dev/null 2>&1") ? "marp" : "npx -y @marp-team/marp-cli"
  end

  def setup
    FileUtils.mkdir_p(SLIDES_DIST_DIR)
    cmd = marp_cmd
    system("#{cmd} #{SLIDES_MD} -o #{SLIDES_HTML} --html > /dev/null 2>&1")
    system("#{cmd} #{AGY_EN_MD} -o #{AGY_EN_HTML} --html > /dev/null 2>&1") if File.exist?(AGY_EN_MD)
    system("#{cmd} #{AGY_IT_MD} -o #{AGY_IT_HTML} --html > /dev/null 2>&1") if File.exist?(AGY_IT_MD)
  end

  def test_slides_md_has_valid_frontmatter
    assert File.exist?(SLIDES_MD), "slides/index.md must exist"
    content = File.read(SLIDES_MD, encoding: "utf-8")
    assert_match(/^marp:\s*true/m, content)
    assert_match(/^theme:\s*gaia/m, content)
    assert_match(/^paginate:\s*true/m, content)
  end

  def test_antigravity_en_and_it_decks_exist_and_have_valid_frontmatter_and_prompts
    %w[
      codelab-page1-intro.png
      agy-step1-new-project.png
      agy-step2-select-folder.png
      agy-step3-project-settings.png
      agy-step4-turbo-mode.png
    ].each do |img|
      assert File.exist?(File.join(REPO_ROOT, "slides/images", img)), "Screenshot slides/images/#{img} must exist"
    end

    [AGY_EN_MD, AGY_IT_MD].each do |deck_path|
      assert File.exist?(deck_path), "#{File.basename(deck_path)} must exist"
      content = File.read(deck_path, encoding: "utf-8")
      assert_match(/^marp:\s*true/m, content)
      assert_match(/^theme:\s*gaia/m, content)
      assert_match(/^paginate:\s*true/m, content)
      # Must contain WSL note for Windows
      assert_match(/WSL/i, content, "#{File.basename(deck_path)} must mention WSL for Windows")
      # Must contain Step 1.5 Codelab Page 1 (#0) screenshot and QR code
      assert_match(/codelab-page1-intro\.png/, content)
      assert_match(/codelab-qr\.png/, content)
      # Must contain Prompt 1 (git clone into Documents + sound)
      assert_match(%r{https://github\.com/palladius/rails8-app-on-gcp/}, content)
      assert_match(/git clone/i, content)
      assert_match(/Documents/i, content)
      # Must contain Step 4 Turbo mode instruction, 4 screenshots, and PROD disclaimer
      assert_match(/TURBO/i, content, "#{File.basename(deck_path)} must mention TURBO mode")
      assert_match(/agy-step1-new-project\.png/, content)
      assert_match(/agy-step2-select-folder\.png/, content)
      assert_match(/agy-step3-project-settings\.png/, content)
      assert_match(/agy-step4-turbo-mode\.png/, content)
      assert_match(/PROD/i, content, "#{File.basename(deck_path)} must include the DO NOT DO IN PROD disclaimer")
      # Must contain Prompt 2 (Codelab + landing-page README)
      assert_match(%r{https://codelabs\.developers\.google\.com/codelabs/rails8-on-google-cloud}, content)
      assert_match(%r{workshop/landing-page/README}, content)
      # Must contain Step 2.5 Credits on Page 2 (#1) and Green button check
      assert_match(/#1/, content)
      # Must contain Prompt 3 (GCP project creation after coupon)
      assert_match(/workshop-(rails8|wbh|modena)-YYYYMMDD/i, content)
    end
  end

  def test_no_unrendered_html_tags_or_code_escaped_markup_in_rendered_slides
    [SLIDES_HTML, AGY_EN_HTML, AGY_IT_HTML].each do |html_path|
      assert File.exist?(html_path), "Rendered slides HTML #{File.basename(html_path)} must exist"
      html = File.read(html_path, encoding: "utf-8")

      # In Marp, when indentation causes HTML to be parsed as code block,
      # it gets wrapped in <pre ...><code>&lt;div... or &lt;button...
      code_block_divs = html.scan(/<code>.*?&lt;div\s+style.*?<\/code>/m)
      assert_empty code_block_divs, "Found unrendered <div style> escaped inside code block in #{File.basename(html_path)}:\n#{code_block_divs.join("\n")}"

      code_block_buttons = html.scan(/<code>.*?&lt;button.*?<\/code>/m)
      assert_empty code_block_buttons, "Found unrendered <button> escaped inside code block in #{File.basename(html_path)}:\n#{code_block_buttons.join("\n")}"

      # Also ensure no raw unrendered literal text like '<div style=' or '<button onclick' is visible outside attributes
      text_leaks = html.scan(/&lt;div\s+style=[^&]*&gt;/)
      assert_empty text_leaks, "Found literal escaped &lt;div style=...&gt; in #{File.basename(html_path)}:\n#{text_leaks.join("\n")}"

      text_button_leaks = html.scan(/&lt;button\s+onclick=[^&]*&gt;/)
      assert_empty text_button_leaks, "Found literal escaped &lt;button onclick=...&gt; in #{File.basename(html_path)}:\n#{text_button_leaks.join("\n")}"
    end
  end

  # A link that swallows the deck is a live-presentation bug: the presenter loses their
  # slides mid-talk and has to hit Back on a projector. Reported twice in the friction
  # logs (Antigravity download link, then the "Claim GCP Credits" button), hence a test.
  def test_external_links_in_slides_open_in_a_new_tab
    offenders = []

    ALL_SLIDE_SOURCES.each do |path|
      File.readlines(path, encoding: "utf-8", chomp: true).each_with_index do |line, index|
        line.scan(/<a\s+[^>]*href="https?:\/\/[^"]*"[^>]*>/) do |tag|
          next if tag.include?('target="_blank"')

          offenders << "#{File.basename(path)}:#{index + 1}: #{tag.strip[0, 120]}"
        end
      end
    end

    assert_empty offenders, <<~MSG
      External slide links must open in a new tab, otherwise clicking one replaces the deck:
      #{offenders.join("\n")}

      Add `target="_blank" rel="noopener noreferrer"` to each link.
    MSG
  end

  def test_rendered_png_images_can_be_generated
    stdout, stderr, status = Open3.capture3("#{marp_cmd} --images png --allow-local-files #{SLIDES_MD} -o #{SLIDES_DIST_DIR}/slide.png")
    assert_equal 0, status.exitstatus, "Marp image rendering failed: #{stderr}"

    # Ensure slide 5 was generated and has non-zero size
    slide5 = File.join(SLIDES_DIST_DIR, "slide.005.png")
    assert File.exist?(slide5), "Slide 5 PNG was not generated"
    assert File.size(slide5) > 10_000, "Slide 5 PNG is suspiciously small (#{File.size(slide5)} bytes)"
  end
end
