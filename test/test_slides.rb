require "minitest/autorun"
require "open3"
require "fileutils"

class SlidesTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)
  SLIDES_MD = File.join(REPO_ROOT, "slides/index.md")
  SLIDES_DIST_DIR = File.join(REPO_ROOT, "slides/dist")
  SLIDES_HTML = File.join(SLIDES_DIST_DIR, "index.html")

  def setup
    FileUtils.mkdir_p(SLIDES_DIST_DIR)
    marp_cmd = system("which marp > /dev/null 2>&1") ? "marp" : "npx -y @marp-team/marp-cli"
    system("#{marp_cmd} #{SLIDES_MD} -o #{SLIDES_HTML} --html > /dev/null 2>&1")
  end

  def test_slides_md_has_valid_frontmatter
    assert File.exist?(SLIDES_MD), "slides/index.md must exist"
    content = File.read(SLIDES_MD)
    assert_match(/^marp:\s*true/m, content)
    assert_match(/^theme:\s*gaia/m, content)
    assert_match(/^paginate:\s*true/m, content)
  end

  def test_no_unrendered_html_tags_or_code_escaped_markup_in_rendered_slides
    assert File.exist?(SLIDES_HTML), "Rendered slides HTML must exist"
    html = File.read(SLIDES_HTML)

    # In Marp, when indentation causes HTML to be parsed as code block,
    # it gets wrapped in <pre ...><code>&lt;div... or &lt;button...
    code_block_divs = html.scan(/<code>.*?&lt;div\s+style.*?<\/code>/m)
    assert_empty code_block_divs, "Found unrendered <div style> escaped inside code block:\n#{code_block_divs.join("\n")}"

    code_block_buttons = html.scan(/<code>.*?&lt;button.*?<\/code>/m)
    assert_empty code_block_buttons, "Found unrendered <button> escaped inside code block:\n#{code_block_buttons.join("\n")}"

    # Also ensure no raw unrendered literal text like '<div style=' or '<button onclick' is visible outside attributes
    text_leaks = html.scan(/&lt;div\s+style=[^&]*&gt;/)
    assert_empty text_leaks, "Found literal escaped &lt;div style=...&gt; in slides HTML:\n#{text_leaks.join("\n")}"

    text_button_leaks = html.scan(/&lt;button\s+onclick=[^&]*&gt;/)
    assert_empty text_button_leaks, "Found literal escaped &lt;button onclick=...&gt; in slides HTML:\n#{text_button_leaks.join("\n")}"
  end

  def test_rendered_png_images_can_be_generated
    marp_cmd = system("which marp > /dev/null 2>&1") ? "marp" : "npx -y @marp-team/marp-cli"
    stdout, stderr, status = Open3.capture3("#{marp_cmd} --images png --allow-local-files #{SLIDES_MD} -o #{SLIDES_DIST_DIR}/slide.png")
    assert_equal 0, status.exitstatus, "Marp image rendering failed: #{stderr}"

    # Ensure slide 5 was generated and has non-zero size
    slide5 = File.join(SLIDES_DIST_DIR, "slide.005.png")
    assert File.exist?(slide5), "Slide 5 PNG was not generated"
    assert File.size(slide5) > 10_000, "Slide 5 PNG is suspiciously small (#{File.size(slide5)} bytes)"
  end
end
