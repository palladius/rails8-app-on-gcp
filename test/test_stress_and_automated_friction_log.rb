# frozen_string_literal: true

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require "minitest/autorun"
require "open3"
require "tmpdir"
require "fileutils"
require "yaml"
require "digest"
require_relative "../bin/ensure_workshop_credentials"

# Comprehensive Stress-Test & Automated Friction-Log Simulation Suite
#
# Runs two full automated Friction-Log simulations:
# 1. Automated Friction Log #1 (Clean-Room Student Journey Steps 0 -> 8):
#    Clones the working tree into an isolated temp workspace, mocks external GCP CLIs,
#    and executes the full progression (Step 0 -> Step 1 diagnostics/credentials bootstrap ->
#    Step 3 Time-Machine Stage 1 -> Step 4 Time-Machine Stage 2 -> Step 5 Cloud SQL/Secrets ->
#    Step 6 Gold Standard restore + 3-tier sidecars -> Step 7 Vertex AI ADC -> Step 8 Quests).
# 2. Automated Friction Log #2 (Adversarial / Chaos Student & 4-Surface Sync Audit):
#    Stress-tests every historical footgun from FL001..FL008, Daniel Strebel's friction log,
#    Guillaume Laforge's raw .md endpoints, and bash -n syntax across all 39+
#    code blocks in CODELAB.md and DevSite index.lab.md.
class StressAndAutomatedFrictionLogTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)
  CODELAB_PATH = File.join(REPO_ROOT, "workshop", "CODELAB.md")
  DEVSITE_PATH = File.join(REPO_ROOT, "workshop", "build", "devsite", "index.lab.md")
  SKELETON_YAML_PATH = File.join(REPO_ROOT, "workshop", "skeleton.yaml")

  def build_mock_cli_env(dir, active_account: "student@gmail.com", master_key: "a1b2c3d4e5f60718293a4b5c6d7e8f90")
    bin_dir = File.join(dir, "mockbin")
    FileUtils.mkdir_p(bin_dir)

    fake_gcloud = File.join(bin_dir, "gcloud")
    File.write(fake_gcloud, <<~SH)
      #!/bin/sh
      case "$*" in
        "version"*) echo "Google Cloud SDK 500.0.0" ;;
        "auth list --filter=status:ACTIVE"*) echo "#{active_account}" ;;
        "auth list"*) echo "#{active_account}" ;;
        "config get-value project"*) echo "fl-sim-project" ;;
        "config configurations list"*) echo "rails8-on-gcp-workshop" ;;
        "beta billing projects describe"*) echo "True" ;;
        "auth application-default print-access-token"*) echo "mock-adc-token" ;;
        "projects describe"*) echo "123456789012" ;;
        "projects get-iam-policy"*) echo "roles/editor" ;;
        "storage buckets describe"*) exit 0 ;;
        "storage ls"*) exit 0 ;;
        "run services describe"*) echo "https://blog-123456789012.europe-west1.run.app" ;;
        "services list"*) echo "secretmanager.googleapis.com" ;;
        "sql instances list"*) echo "rails8-sql-sim RUNNABLE" ;;
        "secrets versions access latest --secret=rails-master-key"*) printf "%s" "#{master_key}" ;;
        "secrets versions add"*) exit 0 ;;
        *) exit 0 ;;
      esac
    SH
    File.chmod(0o755, fake_gcloud)

    %w[docker terraform].each do |tool|
      tool_path = File.join(bin_dir, tool)
      File.write(tool_path, "#!/bin/sh\necho '#{tool} mock 1.0.0'\nexit 0\n")
      File.chmod(0o755, tool_path)
    end

    fake_node = File.join(bin_dir, "node")
    File.write(fake_node, "#!/bin/sh\nexit 0\n")
    File.chmod(0o755, fake_node)

    rbenv_shims = File.expand_path("~/.rbenv/shims")
    {
      "PATH" => "#{bin_dir}:#{rbenv_shims}:#{ENV['PATH']}",
      "RBENV_VERSION" => "3.4.5",
      "BUNDLE_USER_HOME" => "/tmp/bundle",
      "RAILS_MASTER_KEY" => nil,
      # Keep the simulation hermetic: never read the host's Antigravity config.
      "GEMINI_CONFIG_DIR" => File.join(dir, "gemini-config-empty"),
      "GOOGLE_CLOUD_PROJECT" => "fl-sim-project",
      "GOOGLE_CLOUD_REGION" => "europe-west1",
      "GOOGLE_CLOUD_ACCOUNT" => active_account
    }
  end

  # =========================================================================
  # AUTOMATED FRICTION LOG #1: Clean-Room Student Journey (Steps 0 -> 8)
  # =========================================================================
  def test_automated_friction_log_1_clean_student_journey_steps_0_to_8
    Dir.mktmpdir("fl1-clean-student-") do |ws|
      # 1. Clone repo and copy current working tree changes into isolated student workspace
      _out, err, st = Open3.capture3("git", "clone", "--quiet", REPO_ROOT, ws)
      assert st.success?, "git clone failed: #{err}"

      %w[
        .env.dist
        bin/workshop_diagnostics.rb
        bin/workshop_eval.rb
        lib/workshop_eval/invariant_checker.rb
        lib/workshop_eval/live_check.rb
        bin/workshop_time_machine.rb
        bin/ensure_workshop_credentials.rb
        blog/compose.prod.yaml
        blog/lib/nanobanana.rb
        blog/app/controllers/statuses_controller.rb
        blog/app/controllers/concerns/iap_authenticatable.rb
        workshop/CODELAB.md
        workshop/SKELETON.md
        workshop/skeleton.yaml
      ].each do |rel|
        src = File.join(REPO_ROOT, rel)
        dst = File.join(ws, rel)
        FileUtils.mkdir_p(File.dirname(dst))
        FileUtils.cp(src, dst) if File.exist?(src)
      end

      # Ensure credentials.yml.enc starts at the fresh maintainer sample state (no master.key)
      FileUtils.rm_f(File.join(ws, "blog/config/master.key"))
      sample_creds, _, _ = Open3.capture3("git", "-C", REPO_ROOT, "show", "HEAD:blog/config/credentials.yml.enc")
      File.binwrite(File.join(ws, "blog/config/credentials.yml.enc"), sample_creds)
      assert_equal WorkshopCredentialsManager::SAMPLE_APP_CREDENTIALS_MD5,
                   Digest::MD5.file(File.join(ws, "blog/config/credentials.yml.enc")).hexdigest

      # Commit working-tree updates in the student sandbox so `restore-gold` (`git checkout blog/config/`) works cleanly
      Open3.capture3("git", "-C", ws, "-c", "user.email=student@example.com", "-c", "user.name=Student", "commit", "-am", "sync working tree")

      # Link bundle cache from main repo so `bin/rails runner` works fast offline
      if Dir.exist?(File.join(REPO_ROOT, "blog/vendor/bundle"))
        FileUtils.mkdir_p(File.join(ws, "blog/vendor"))
        File.symlink(File.join(REPO_ROOT, "blog/vendor/bundle"), File.join(ws, "blog/vendor/bundle")) rescue nil
      end
      if Dir.exist?(File.join(REPO_ROOT, "blog/.bundle"))
        FileUtils.cp_r(File.join(REPO_ROOT, "blog/.bundle"), File.join(ws, "blog/.bundle"))
      end

      env = build_mock_cli_env(ws)

      # --- STEP 0: Prerequisites & Toolchain ---
      out0, err0, st0 = Open3.capture3(env, "ruby", "bin/workshop_eval.rb", "0", chdir: ws)
      assert st0.success?, "FL1 Step 0 eval failed:\n#{out0}\n#{err0}"

      # --- STEP 1: Copy .env.dist -> .env & Run Pre-Flight Diagnostics ---
      FileUtils.cp(File.join(ws, ".env.dist"), File.join(ws, ".env"))
      File.open(File.join(ws, ".env"), "a") do |f|
        f.puts "\nGOOGLE_CLOUD_ACCOUNT=\"student@gmail.com\""
        f.puts "GOOGLE_CLOUD_PROJECT=\"fl-sim-project\""
        f.puts "GOOGLE_CLOUD_REGION=\"europe-west1\""
      end

      out1, err1, st1 = Open3.capture3(env, "ruby", "bin/workshop_eval.rb", "1", chdir: ws)
      assert st1.success?, "FL1 Step 1 eval failed:\n#{out1}\n#{err1}"

      # Verify Step 1 diagnostics automatically bootstrapped and paired master.key + credentials.yml.enc
      cred_state = WorkshopCredentialsManager.check(repo_root: ws)
      assert_equal :ok, cred_state[:status], "Step 1 diagnostics must leave master.key + credentials.yml.enc paired"
      refute cred_state[:is_sample_app_md5], "credentials.yml.enc must no longer have maintainer sample MD5"
      student_creds_md5 = Digest::MD5.file(File.join(ws, "blog/config/credentials.yml.enc")).hexdigest

      # --- STEP 3: Time-Machine Rewind 1 (Stateless SQLite) ---
      _o, e3_tm, s3_tm = Open3.capture3(env, "ruby", "bin/workshop_time_machine.rb", "rewind", "1", chdir: ws)
      assert s3_tm.success?, "Time-Machine rewind 1 failed: #{e3_tm}"
      out3, err3, st3 = Open3.capture3(env, "ruby", "bin/workshop_eval.rb", "3", chdir: ws)
      assert st3.success?, "FL1 Step 3 eval failed:\n#{out3}\n#{err3}"

      # --- STEP 4: Time-Machine Rewind 2 (GCS IAM Storage) ---
      _o, e4_tm, s4_tm = Open3.capture3(env, "ruby", "bin/workshop_time_machine.rb", "rewind", "2", chdir: ws)
      assert s4_tm.success?, "Time-Machine rewind 2 failed: #{e4_tm}"
      # Run fast non-rails-suite checks of Step 4 (storage config + invariants)
      storage_yml = File.read(File.join(ws, "blog/config/storage.yml"))
      assert_includes storage_yml, "iam: true", "Stage 2 storage.yml must enable IAM signing"

      # --- STEP 5: Cloud SQL Ready, Secret Manager & Step 5 Telemetry Inference ---
      # Update mock gcloud secret to return the student's newly generated master.key
      student_master_key = File.read(File.join(ws, "blog/config/master.key")).strip
      env = build_mock_cli_env(ws, master_key: student_master_key)
      out5, err5, st5 = Open3.capture3(env, "ruby", "bin/workshop_eval.rb", "5", chdir: ws)
      assert st5.success?, "FL1 Step 5 eval failed:\n#{out5}\n#{err5}"

      # --- STEP 6: Restore Gold Standard & Verify Student Credentials Preserved (#167) ---
      _o, e6_tm, s6_tm = Open3.capture3(env, "ruby", "bin/workshop_time_machine.rb", "restore-gold", chdir: ws)
      assert s6_tm.success?, "Time-Machine restore-gold failed: #{e6_tm}"
      assert_equal student_creds_md5,
                   Digest::MD5.file(File.join(ws, "blog/config/credentials.yml.enc")).hexdigest,
                   "restore-gold MUST NOT overwrite student's paired credentials.yml.enc!"

      # Verify Step 6 status telemetry inference (Cloud SQL + GCS, before Vertex AI ADC)
      skel = YAML.load_file(File.join(ws, "workshop/skeleton.yaml"))
      step6_eval = skel["steps"].find { |s| s["number"] == 6 }["evals"].find { |e| e["id"] == "step-6-ruby-status-json-step" }
      Dir.chdir(ws) { eval(step6_eval["code"]) }

      # --- STEP 7: Vertex AI ADC Telemetry Inference (Zero GEMINI_API_KEY) ---
      step7_eval = skel["steps"].find { |s| s["number"] == 7 }["evals"].find { |e| e["id"] == "step-7-ruby-status-json-step" }
      Dir.chdir(ws) { eval(step7_eval["code"]) }

      # --- STEP 8: Capstone Quests & All 7 Cumulative Invariants ---
      out8, err8, st8 = Open3.capture3(env, "ruby", "bin/workshop_eval.rb", "8", chdir: ws)
      assert st8.success?, "FL1 Step 8 eval (including all 7 cumulative invariants) failed:\n#{out8}\n#{err8}"
      assert_includes out8, "Passed, 0 Failed"
    end
  end

  # =========================================================================
  # AUTOMATED FRICTION LOG #2: Adversarial / Chaos Traps & 4-Surface Audit
  # =========================================================================
  def test_automated_friction_log_2_bash_syntax_on_all_codelab_and_devsite_blocks
    [
      ["workshop/CODELAB.md", CODELAB_PATH],
      ["workshop/build/devsite/index.lab.md", DEVSITE_PATH]
    ].each do |label, path|
      assert File.exist?(path), "#{label} must exist"
      content = File.read(path)
      blocks = content.scan(/^```(?:bash|sh|shell)\n(.*?)^```/m).flatten
      assert_operator blocks.size, :>=, 35, "Expected at least 35 bash blocks in #{label}, found #{blocks.size}"

      blocks.each_with_index do |block, idx|
        sanitized = block.gsub(/<[A-Z0-9_]+>/, "PLACEHOLDER")
        _out, err, st = Open3.capture3("bash", "-n", stdin_data: sanitized)
        assert st.success?, "#{label} bash block ##{idx + 1} failed `bash -n` syntax check:\n#{block}\nError: #{err}"

        # Ensure no interactive `gcloud init` command exists outside comments/warnings
        block.each_line do |line|
          next if line.lstrip.start_with?("#")
          refute_match(/\bgcloud\s+init\b/, line, "#{label} block ##{idx + 1} must never execute `gcloud init` (REQ-01)")
          refute_match(/\bGEMINI_API_KEY\b/, line, "#{label} block ##{idx + 1} must never reference GEMINI_API_KEY (Constitution §11)")
        end
      end
    end
  end

  def test_automated_friction_log_2_all_referenced_images_exist_across_surfaces
    codelab = File.read(CODELAB_PATH)
    images = codelab.scan(/!\[[^\]]*\]\((assets\/images\/[^)]+)\)/).flatten.uniq
    refute_empty images

    images.each do |rel_img|
      src_img = File.join(REPO_ROOT, "workshop", rel_img)
      build_img = File.join(REPO_ROOT, "workshop", "build", rel_img)
      assert File.exist?(src_img), "Missing source image referenced in CODELAB.md: workshop/#{rel_img}"
      assert File.exist?(build_img), "Missing built GitHub Pages image: workshop/build/#{rel_img}"
    end

    devsite = File.read(DEVSITE_PATH)
    devsite_imgs = devsite.scan(%r{!\[[^\]]*\]\(/codelabs/rails8-on-google-cloud/img/([^)]+)\)}).flatten.uniq
    assert_equal images.map { |i| File.basename(i) }.sort, devsite_imgs.sort,
                 "DevSite index.lab.md image references must match CODELAB.md image references 1-to-1"
  end

  def test_automated_friction_log_2_nanobanana_completely_ignores_gemini_api_key_at_runtime
    require File.join(REPO_ROOT, "blog/lib/nanobanana")
    refute Nanobanana.respond_to?(:gemini_api_key), "Nanobanana must not expose .gemini_api_key (Constitution §11)"
    refute Nanobanana.private_methods.include?(:generate_via_gemini_api),
           "Nanobanana must not contain private generate_via_gemini_api method (Constitution §11)"
  end

  def test_automated_friction_log_2_four_surface_build_artifacts_are_in_sync
    # 1. Raw CODELAB.md in workshop/build/ must match workshop/CODELAB.md byte-for-byte (REQ-09)
    %w[
      workshop/build/CODELAB.md
      workshop/build/codelab.md
      workshop/build/workshop/CODELAB.md
    ].each do |built_md|
      full = File.join(REPO_ROOT, built_md)
      assert File.exist?(full), "Missing Agent-Friendly raw Markdown artifact #{built_md} (run build_ghpages.rb)"
      assert_equal File.read(CODELAB_PATH), File.read(full),
                   "#{built_md} is out of sync with workshop/CODELAB.md! Re-run `ruby workshop/visualizer/build_ghpages.rb`."
    end

    # 2. llms.txt must exist and link to CODELAB.md, CONSTITUTION.md, and SKELETON.md
    llms_txt = File.join(REPO_ROOT, "workshop/build/llms.txt")
    assert File.exist?(llms_txt), "workshop/build/llms.txt must exist"
    llms_content = File.read(llms_txt)
    assert_includes llms_content, "CODELAB.md"
    assert_includes llms_content, "CONSTITUTION.md"
    assert_includes llms_content, "SKELETON.md"

    # 3. .env.example symlink must exist and match .env.dist
    env_example = File.join(REPO_ROOT, ".env.example")
    env_dist = File.join(REPO_ROOT, ".env.dist")
    assert File.exist?(env_example), ".env.example must exist (REQ-04)"
    assert_equal File.read(env_dist), File.read(env_example), ".env.example must match .env.dist"
  end
end
