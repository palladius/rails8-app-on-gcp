require "test_helper"
require "open3"

class SlidesPresentationTest < ActiveSupport::TestCase
  SLIDES_MD = File.expand_path("../../../slides/index.md", __dir__)
  SLIDES_DIST_DIR = File.expand_path("../../../slides/dist", __dir__)
  SLIDES_HTML = File.join(SLIDES_DIST_DIR, "index.html")

  test "slides markdown file exists and has valid Marp frontmatter" do
    assert File.exist?(SLIDES_MD), "slides/index.md must exist"
    content = File.read(SLIDES_MD)

    assert_match(/^marp:\s*true/m, content, "Marp frontmatter must have 'marp: true'")
    assert_match(/^theme:\s*gaia/m, content, "Marp frontmatter must specify 'theme: gaia'")
    assert_match(/^paginate:\s*true/m, content, "Marp frontmatter must specify 'paginate: true'")
  end

  test "no slide overflows visual boundaries in rendered presentation" do
    # 1. Compile slides if missing or outdated
    ensure_compiled_slides

    # 2. Skip gracefully if headless Chrome or Selenium cannot be initialized
    begin
      require "selenium-webdriver"
      Selenium::WebDriver.logger.level = :warn

      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument("--headless=new")
      options.add_argument("--disable-gpu")
      options.add_argument("--no-sandbox")
      options.add_argument("--window-size=1280,720")

      driver = Selenium::WebDriver.for :chrome, options: options
    rescue StandardError => e
      skip "Headless Chrome/Selenium not available in this environment: #{e.message}"
    end

    begin
      driver.get("file://#{SLIDES_HTML}")
      sleep 0.5

      # 3. Evaluate visual bounds in Chrome
      slide_metrics = driver.execute_script(%q{
        const sections = Array.from(document.querySelectorAll("section"));
        return sections.map((sec, idx) => {
          const rect = sec.getBoundingClientRect();
          const children = Array.from(sec.querySelectorAll("*"));
          let overflowingEl = null;
          for (const child of children) {
            const cRect = child.getBoundingClientRect();
            if (cRect.bottom > rect.bottom + 2) {
              overflowingEl = `${child.tagName}.${child.className}: ${child.innerText.slice(0, 40).trim()}`;
              break;
            }
          }
          const overflows = (sec.scrollHeight > sec.clientHeight + 2) || (overflowingEl !== null);
          return {
            slide: idx + 1,
            scrollHeight: sec.scrollHeight,
            clientHeight: sec.clientHeight,
            overflows: overflows,
            overflowingEl: overflowingEl
          };
        });
      })

      overflowing_slides = slide_metrics.select { |m| m["overflows"] }

      failure_message = overflowing_slides.map do |m|
        "Slide #{m['slide']} overflows! scrollHeight: #{m['scrollHeight']}px > clientHeight: #{m['clientHeight']}px " \
        "(element: #{m['overflowingEl'] || 'content'})"
      end.join("\n")

      assert_empty overflowing_slides, "Found slides with overflowing content:\n#{failure_message}"
    ensure
      driver&.quit
    end
  end

  private

  def ensure_compiled_slides
    FileUtils.mkdir_p(SLIDES_DIST_DIR)
    if !File.exist?(SLIDES_HTML) || File.mtime(SLIDES_MD) > File.mtime(SLIDES_HTML)
      marp_cmd = system("which marp > /dev/null 2>&1") ? "marp" : "npx -y @marp-team/marp-cli"
      system("#{marp_cmd} #{SLIDES_MD} -o #{SLIDES_HTML} --html > /dev/null 2>&1")
    end
  end
end
