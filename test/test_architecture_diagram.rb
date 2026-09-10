require "minitest/autorun"
require "open3"
require "fileutils"

class ArchitectureDiagramTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)
  DIAGRAMS_DIR = File.join(REPO_ROOT, "diagrams")
  SCRIPT_PATH = File.join(DIAGRAMS_DIR, "generate_diagrams.py")
  PYPROJECT_PATH = File.join(DIAGRAMS_DIR, "pyproject.toml")
  CANONICAL_PNG = File.join(REPO_ROOT, "assets/arch_diagram.png")
  WORKSHOP_PNG = File.join(REPO_ROOT, "workshop/assets/images/arch_diagram.png")
  EVOLUTION_GIF = File.join(REPO_ROOT, "assets/arch_evolution.gif")
  WORKSHOP_GIF = File.join(REPO_ROOT, "workshop/assets/images/arch_evolution.gif")
  CODELAB_PATH = File.join(REPO_ROOT, "workshop/CODELAB.md")
  SKELETON_PATH = File.join(REPO_ROOT, "workshop/SKELETON.md")
  SLIDES_PATH = File.join(REPO_ROOT, "slides/index.md")

  def test_diagram_scripts_exist
    assert File.exist?(PYPROJECT_PATH), "Expected pyproject.toml at #{PYPROJECT_PATH}"
    assert File.exist?(SCRIPT_PATH), "Expected generate_diagrams.py at #{SCRIPT_PATH}"
  end

  def test_canonical_diagram_file_present_and_valid
    assert File.exist?(CANONICAL_PNG), "Expected #{CANONICAL_PNG} to exist"
    assert File.size(CANONICAL_PNG) > 10_000, "Expected #{CANONICAL_PNG} to be larger than 10KB"
    assert File.exist?(WORKSHOP_PNG), "Expected #{WORKSHOP_PNG} to exist"
    assert File.size(WORKSHOP_PNG) > 10_000, "Expected #{WORKSHOP_PNG} to be larger than 10KB"
  end

  def test_evolution_gif_present_and_valid
    assert File.exist?(EVOLUTION_GIF), "Expected #{EVOLUTION_GIF} to exist"
    assert File.size(EVOLUTION_GIF) > 10_000, "Expected #{EVOLUTION_GIF} to be larger than 10KB"
    assert File.exist?(WORKSHOP_GIF), "Expected #{WORKSHOP_GIF} to exist"
    assert File.size(WORKSHOP_GIF) > 10_000, "Expected #{WORKSHOP_GIF} to be larger than 10KB"
  end

  def test_workshop_and_slides_reference_diagram
    codelab_content = File.read(CODELAB_PATH)
    assert_includes codelab_content, "arch_diagram.png", "CODELAB.md must reference arch_diagram.png"

    skeleton_content = File.read(SKELETON_PATH)
    assert_includes skeleton_content, "arch_diagram.png", "SKELETON.md must reference arch_diagram.png"

    slides_content = File.read(SLIDES_PATH)
    assert_includes slides_content, "arch_diagram", "slides/index.md must reference architecture diagram"
  end
end
