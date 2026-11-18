# frozen_string_literal: true

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require "minitest/autorun"
require "yaml"

class CodelabSyncAndContractsTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)
  CODELAB_PATH = File.join(REPO_ROOT, "workshop", "CODELAB.md")
  SKELETON_YAML_PATH = File.join(REPO_ROOT, "workshop", "skeleton.yaml")
  LOCAL_DEVSITE_PATH = File.join(REPO_ROOT, "workshop", "build", "devsite", "index.lab.md")
  DEVSITE_LAB_PATH = if File.exist?(LOCAL_DEVSITE_PATH)
    LOCAL_DEVSITE_PATH
  elsif ENV["DEVSITE_CODELAB_PATH"] && File.exist?(ENV["DEVSITE_CODELAB_PATH"]) && File.writable?(ENV["DEVSITE_CODELAB_PATH"])
    ENV["DEVSITE_CODELAB_PATH"]
  else
    LOCAL_DEVSITE_PATH
  end

  def setup
    @codelab = File.read(CODELAB_PATH)
    @skeleton = YAML.load_file(SKELETON_YAML_PATH)
  end

  def extract_step_section(markdown, step_num)
    pattern = /^## Step #{step_num}:.*?(?=^## (?:Step \d+|🎓 Conclusion)|\z)/m
    match = markdown.match(pattern)
    assert match, "Could not find '## Step #{step_num}:' in CODELAB.md"
    match[0]
  end

  # Finding #1 (FL_E001): $GOOGLE_CLOUD_PROJECT and $GOOGLE_CLOUD_ACCOUNT must be exported
  # BEFORE they are used in `gcloud auth login` or `gcloud config set project`, and
  # `gcloud projects create` must be present in Step 0.
  def test_step_0_exports_variables_before_first_use_and_creates_project
    step0 = extract_step_section(@codelab, 0)

    export_account_pos = step0.index(/export\s+GOOGLE_CLOUD_ACCOUNT=/)
    export_project_pos = step0.index(/export\s+GOOGLE_CLOUD_PROJECT=/)
    export_region_pos  = step0.index(/export\s+GOOGLE_CLOUD_REGION=/)

    refute_nil export_account_pos, "Step 0 must explicitly define 'export GOOGLE_CLOUD_ACCOUNT=...'"
    refute_nil export_project_pos, "Step 0 must explicitly define 'export GOOGLE_CLOUD_PROJECT=...'"
    refute_nil export_region_pos,  "Step 0 must explicitly define 'export GOOGLE_CLOUD_REGION=...'"

    auth_login_pos = step0.index(/gcloud\s+auth\s+login\s+\$GOOGLE_CLOUD_ACCOUNT/)
    set_project_pos = step0.index(/gcloud\s+config\s+set\s+project\s+\$GOOGLE_CLOUD_PROJECT/)

    refute_nil auth_login_pos, "Step 0 must include 'gcloud auth login $GOOGLE_CLOUD_ACCOUNT'"
    refute_nil set_project_pos, "Step 0 must include 'gcloud config set project $GOOGLE_CLOUD_PROJECT'"

    assert export_account_pos < auth_login_pos,
           "export GOOGLE_CLOUD_ACCOUNT must appear BEFORE 'gcloud auth login $GOOGLE_CLOUD_ACCOUNT' in Step 0"
    assert export_project_pos < set_project_pos,
           "export GOOGLE_CLOUD_PROJECT must appear BEFORE 'gcloud config set project $GOOGLE_CLOUD_PROJECT' in Step 0"

    assert_match(/gcloud\s+projects\s+create\s+\$GOOGLE_CLOUD_PROJECT/, step0,
                 "Step 0 must instruct users how to create the project via 'gcloud projects create $GOOGLE_CLOUD_PROJECT'")
    assert_match(/gcloud\s+auth\s+application-default\s+set-quota-project\s+\$GOOGLE_CLOUD_PROJECT/, step0,
                 "Step 0 must set ADC quota project via 'gcloud auth application-default set-quota-project $GOOGLE_CLOUD_PROJECT'")
  end

  # Finding #2 (FL_E001): `gcloud config set compute/region` prompts to enable compute.googleapis.com
  # on virgin projects (which fails before billing is linked) and is never used by Cloud Run.
  def test_no_gcloud_config_set_compute_region_in_codelab
    refute_match(/gcloud\s+config\s+set\s+compute\/region/, @codelab,
                 "CODELAB.md must NOT run 'gcloud config set compute/region' (triggers compute.googleapis.com prompt; use run/region instead)")
  end

  # Finding #3 & #7 (FL_E001): Billing verification must distinguish having an account vs linking it,
  # include `gcloud billing projects link`, link to `billing/linkedaccount?project=`, and mention credit duration.
  def test_step_0_billing_includes_link_command_and_project_billing_url
    step0 = extract_step_section(@codelab, 0)
    assert_match(/gcloud\s+billing\s+projects\s+link\s+\$GOOGLE_CLOUD_PROJECT/, step0,
                 "Step 0 must include 'gcloud billing projects link $GOOGLE_CLOUD_PROJECT --billing-account=...'")
    assert_match(%r{console\.cloud\.google\.com/billing/linkedaccount\?project=}, step0,
                 "Step 0 must link directly to project billing linkage page (billing/linkedaccount?project=...)")
    assert_match(/SUSPENDED|same-day|single session|overnight/i, step0,
                 "Step 0 must warn that temporary workshop credits can suspend overnight (SUSPENDED / BILLING_ISSUE)")
  end

  # Finding #4 (FL_E001): In Step 1, `cp .env.dist .env` must come BEFORE `just workshop-test`.
  def test_step_1_copies_dotenv_before_running_workshop_test
    step1 = extract_step_section(@codelab, 1)
    cp_env_pos = step1.index(/cp\s+\.env\.dist\s+\.env/)
    workshop_test_pos = step1.index(/just\s+workshop-test/)

    refute_nil cp_env_pos, "Step 1 must instruct user to run 'cp .env.dist .env'"
    refute_nil workshop_test_pos, "Step 1 must instruct user to run 'just workshop-test'"
    assert cp_env_pos < workshop_test_pos,
           "'cp .env.dist .env' must appear BEFORE 'just workshop-test' in Step 1 so diagnostics find .env on first run"
  end

  # Finding #5 (FL_E001) & Constitution §9: No "Mode A" / "Mode B" references in CODELAB.md
  def test_no_forking_roads_mode_a_or_mode_b_in_codelab
    refute_match(/\bMode\s+[AB]\b/i, @codelab,
                 "CODELAB.md must not reference 'Mode A' or 'Mode B' (violates Constitution §9 Single Canonical Path)")
  end

  # Finding #6 & #8 (FL_E001): Step 3 deploy must pass APP_ADMIN_PASSWORD (or source .env),
  # label the SOLID_QUEUE_IN_PUMA update as Deploy 2, and remove SOLID_QUEUE_IN_PUMA + cap --max-instances 1.
  def test_step_3_passes_admin_password_and_cleans_up_solid_queue_in_puma
    step3 = extract_step_section(@codelab, 3)
    assert_match(/APP_ADMIN_PASSWORD/, step3,
                 "Step 3 deploy must pass APP_ADMIN_PASSWORD so .env admin credentials work on Cloud Run")
    assert_match(/Deploy 2/i, step3,
                 "Step 3 must explicitly label the SOLID_QUEUE_IN_PUMA update as 'Deploy 2' so Deploy 1->2->3->4 numbering is contiguous")
    assert_match(/--remove-env-vars\s+SOLID_QUEUE_IN_PUMA/, step3,
                 "Step 3 must remove SOLID_QUEUE_IN_PUMA (--remove-env-vars SOLID_QUEUE_IN_PUMA) after demonstrating the trap to prevent Step 4 512MiB OOM")
  end

  # Finding #7 & #8 (FL_E001): Step 4 deploy must include GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT,
  # ACTIVE_STORAGE_SERVICE=google, and --max-instances 1, matching skeleton.yaml!
  def test_step_4_deploy_includes_google_cloud_project_and_matches_skeleton
    step4 = extract_step_section(@codelab, 4)
    assert_match(/--update-env-vars[^\n]*GOOGLE_CLOUD_PROJECT=\$GOOGLE_CLOUD_PROJECT/, step4,
                 "Step 4 'gcloud run deploy' in CODELAB.md must include GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT in --update-env-vars")
    assert_match(/--update-env-vars[^\n]*ACTIVE_STORAGE_SERVICE=google/, step4,
                 "Step 4 'gcloud run deploy' in CODELAB.md must include ACTIVE_STORAGE_SERVICE=google")

    skel_step4 = @skeleton["steps"].find { |s| s["number"] == 4 }
    refute_nil skel_step4
    assert_match(/GOOGLE_CLOUD_PROJECT=\$GOOGLE_CLOUD_PROJECT/, skel_step4["pseudocode"],
                 "Step 4 pseudocode in skeleton.yaml must also include GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT")
  end

  # Finding #9 (FL_E001) & Decision #1: Unified Custom Service Account `rails-cloudrun-sa` everywhere!
  # Codelab must NOT use Default Compute SA (`-compute@developer.gserviceaccount.com`) for RUN_SA.
  def test_unified_custom_service_account_rails_cloudrun_sa_across_codelab
    refute_match(/export\s+RUN_SA=.*-compute@developer\.gserviceaccount\.com/, @codelab,
                 "CODELAB.md must NOT set RUN_SA to the Default Compute SA (-compute@developer.gserviceaccount.com); must unify on rails-cloudrun-sa")
    assert_match(/export\s+RUN_SA="rails-cloudrun-sa@\$\{?GOOGLE_CLOUD_PROJECT\}?\.iam\.gserviceaccount\.com"/, @codelab,
                 "CODELAB.md must set RUN_SA to rails-cloudrun-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com")
  end

  # Finding #9 (FL_E001): Deploy numbering 1, 2, 3, 4 must be contiguous across CODELAB.md and skeleton.yaml
  def test_deploy_numbering_is_contiguous_1_2_3_4
    (1..4).each do |n|
      assert_match(/Deploy\s+#{n}\b/i, @codelab, "CODELAB.md is missing 'Deploy #{n}'")
    end
  end

  def test_devsite_index_lab_md_is_synced_with_codelab_md
    local_devsite = File.join(REPO_ROOT, "workshop", "build", "devsite", "index.lab.md")
    assert File.exist?(local_devsite), "workshop/build/devsite/index.lab.md must exist (run bin/sync_devsite_codelab.rb)"
    devsite_content = File.read(local_devsite)
    refute_match(/export\s+RUN_SA=.*-compute@developer\.gserviceaccount\.com/, devsite_content,
                 "DevSite index.lab.md must NOT set RUN_SA to Default Compute SA")
    assert_match(/export\s+RUN_SA="rails-cloudrun-sa@\$\{?GOOGLE_CLOUD_PROJECT\}?\.iam\.gserviceaccount\.com"/, devsite_content,
                 "DevSite index.lab.md must set RUN_SA to rails-cloudrun-sa")
    assert_match(/--remove-env-vars\s+SOLID_QUEUE_IN_PUMA/, devsite_content,
                 "DevSite index.lab.md must include SOLID_QUEUE_IN_PUMA cleanup in Step 3")
  end

  def test_root_and_blog_ruby_version_files_match
    root_rv = File.join(REPO_ROOT, ".ruby-version")
    blog_rv = File.join(REPO_ROOT, "blog", ".ruby-version")
    assert File.exist?(root_rv), ".ruby-version must exist at repository root so rbenv works outside blog/"
    assert File.exist?(blog_rv), "blog/.ruby-version must exist"
    assert_equal File.read(blog_rv).strip, File.read(root_rv).strip,
                 "Root .ruby-version and blog/.ruby-version must specify the exact same Ruby version"
  end

  # Issue #169: `--allow-unauthenticated` belongs to `gcloud run deploy`; `gcloud run services update`
  # rejects it ("unrecognized arguments") and then applies NOTHING, including a valid --service-account.
  def test_codelab_gcloud_run_services_update_never_uses_allow_unauthenticated
    offenders = []
    @codelab.scan(/^```(?:bash|sh|shell)\n(.*?)^```/m) do |(block)|
      block.gsub(/\\\n\s*/, " ").each_line do |line|
        next unless line.include?("gcloud run services update")
        offenders << line.strip if line.include?("--allow-unauthenticated")
      end
    end
    assert_empty offenders, "`gcloud run services update` does not accept --allow-unauthenticated:\n  #{offenders.join("\n  ")}"
  end

  # Issue #165: in an interactive bash/zsh, `!!` outside single quotes is expanded to the
  # previous command BEFORE evaluation, so pasting a block containing it mangles the command.
  # The default seeded password therefore must not contain `!`, and no pasteable bash
  # block in the codelab may contain a history-expansion sequence.
  def test_default_admin_password_has_no_history_expansion_characters
    root = File.expand_path("..", __dir__)
    refute_includes @codelab, "Ch4ng3m3!!1", "CODELAB.md must not use the old default password (contains '!!')"
    env_default = File.read(File.join(root, ".env.dist"))[/^APP_ADMIN_PASSWORD="?([^"\n]+)"?/, 1]
    seeds_default = File.read(File.join(root, "blog", "db", "seeds.rb"))[/admin_password = "([^"]+)" if admin_password\.blank\?/, 1]
    assert env_default, ".env.dist must define APP_ADMIN_PASSWORD"
    assert seeds_default, "blog/db/seeds.rb must define a default admin password"
    refute_match(/!/, env_default, ".env.dist default password must not contain '!'")
    refute_match(/!/, seeds_default, "seeds.rb default password must not contain '!'")
    assert_equal env_default, seeds_default, ".env.dist and seeds.rb defaults must match"
  end

  def test_codelab_bash_blocks_contain_no_history_expansion
    offenders = []
    @codelab.scan(/^```(?:bash|sh|shell)\n(.*?)^```/m) do |(block)|
      block.each_line do |line|
        next if line.lstrip.start_with?("#")
        offenders << line.strip if line.include?("!!") || line.match?(/![A-Za-z0-9$\-?]/)
      end
    end
    assert_empty offenders, "Bash blocks must not contain history expansion (`!!`, `!word`):\n  #{offenders.join("\n  ")}"
  end

  def test_step_2_documents_default_seeded_password_and_just_compose_up
    step2 = extract_step_section(@codelab, 2)
    assert_match(/just\s+compose-up/, step2, "Step 2 must instruct user to run 'just compose-up'")
    assert_match(/Ch4ng3m3-1/, step2, "Step 2 must explicitly mention the default seeded password 'Ch4ng3m3-1'")
  end

  def test_step_3_explicitly_states_default_seeded_password_not_just_variable_name
    step3 = extract_step_section(@codelab, 3)
    assert_match(/Ch4ng3m3-1/, step3,
                 "Step 3 must explicitly state the default seeded password 'Ch4ng3m3-1' so users aren't confused by APP_ADMIN_PASSWORD")
    assert_match(/--max-instances\s+1/, step3,
                 "Step 3 must pin --max-instances 1 when cleaning up SOLID_QUEUE_IN_PUMA so SQLite sessions don't split across instances in Step 4")
  end

  def test_step_4_binds_custom_service_account_and_storage_iam_roles
    step4 = extract_step_section(@codelab, 4)
    assert_match(/--service-account\s+\$RUN_SA/, step4,
                 "Step 4 'gcloud run deploy' must explicitly bind --service-account $RUN_SA")
    assert_match(/roles\/storage\.objectAdmin/, step4,
                 "Step 4 must verify/grant roles/storage.objectAdmin to $RUN_SA")
    assert_match(/roles\/iam\.serviceAccountTokenCreator/, step4,
                 "Step 4 must verify/grant roles/iam.serviceAccountTokenCreator to $RUN_SA")
  end

  def test_step_5_uses_ensure_workshop_credentials_and_checks_secret_iam_for_run_sa
    step5 = extract_step_section(@codelab, 5)
    assert_match(/ensure_workshop_credentials\.rb\s+--sync-gcp/, step5,
                 "Step 5 must use 'ruby bin/ensure_workshop_credentials.rb --sync-gcp' for atomic master.key + credentials.yml.enc pairing")
    assert_match(/gcloud\s+secrets\s+get-iam-policy\s+rails-master-key/, step5,
                 "Step 5.4 must inspect secret-level IAM policy on rails-master-key")
    assert_match(/serviceAccount:rails-cloudrun-sa@/, step5,
                 "Step 5.4 expected output must show serviceAccount:rails-cloudrun-sa@... as the Secret Accessor member")
  end

  def test_step_6_compose_up_followed_by_service_account_binding
    step6 = extract_step_section(@codelab, 6)
    compose_pos = step6.index(/gcloud\s+run\s+compose\s+up\s+compose\.prod\.yaml/)
    update_sa_pos = step6.index(/gcloud\s+run\s+services\s+update\s+blog[^\n]*\n(?:[^\n]*\n)*?[^\n]*--service-account=\$RUN_SA/)
    refute_nil compose_pos, "Step 6 must run 'gcloud run compose up compose.prod.yaml'"
    refute_nil update_sa_pos, "Step 6 must run 'gcloud run services update blog ... --service-account=$RUN_SA' right after compose up"
    assert compose_pos < update_sa_pos,
           "'gcloud run services update blog --service-account=$RUN_SA' must run AFTER 'gcloud run compose up' in Step 6"
  end

  # Constraint WC-04 (friction log FL014): `gcloud run compose up` cannot attach existing secrets,
  # and a variable it sets as a literal cannot later become a secret. So Step 6 must mount both
  # secrets AFTER compose up, on web AND worker, in a command that names each container.
  def test_step_6_mounts_secrets_on_web_and_worker_after_compose_up
    step6 = extract_step_section(@codelab, 6)
    compose_pos = step6.index(/gcloud\s+run\s+compose\s+up\s+compose\.prod\.yaml/)
    update = step6[/gcloud run services update blog \\\n(?:[^\n]*\\\n)*[^\n]*\n/]
    refute_nil compose_pos, "Step 6 must run 'gcloud run compose up compose.prod.yaml'"
    refute_nil update, "Step 6 must run a multi-line 'gcloud run services update blog'"
    assert compose_pos < step6.index(update), "the secrets must be mounted after compose up"
    %w[web worker].each do |container|
      assert_match(/--container=#{container}\s[^\n]*--set-secrets=/, update,
                   "Step 6 must mount the secrets on the '#{container}' container (--container=#{container} ... --set-secrets=...)")
    end
    secrets = step6[/APP_SECRETS="([^"]+)"/, 1].to_s
    %w[RAILS_MASTER_KEY=rails-master-key DB_PASSWORD=rails-db-password].each do |pair|
      assert_includes secrets, pair, "Step 6 must mount #{pair.split('=').first} from Secret Manager"
    end
  end

  def test_skeleton_yaml_evals_pin_rbenv_version_3_4_5
    %w[step-5 step-6 step-7].each do |step_id|
      step = @skeleton["steps"].find { |s| s["id"] == step_id }
      refute_nil step, "Missing #{step_id} in skeleton.yaml"
      eval_item = step["evals"].find { |e| e["id"] == "#{step_id}-ruby-status-json-step" }
      refute_nil eval_item, "Missing #{step_id}-ruby-status-json-step in skeleton.yaml"
      assert_match(/"RBENV_VERSION"\s*=>\s*"3\.4\.5"/, eval_item["code"],
                   "#{step_id}-ruby-status-json-step must set RBENV_VERSION => 3.4.5 in Open3.capture3 env")
    end
  end

  def test_codelab_version_and_changelog_synced_in_last_page_footer
    version_path = File.join(REPO_ROOT, "workshop/CODELAB_VERSION")
    changelog_path = File.join(REPO_ROOT, "workshop/CODELAB_CHANGELOG.md")
    assert File.exist?(version_path), "workshop/CODELAB_VERSION must exist"
    assert File.exist?(changelog_path), "workshop/CODELAB_CHANGELOG.md must exist"

    codelab_version = File.read(version_path).strip
    refute_empty codelab_version, "workshop/CODELAB_VERSION must not be empty"

    changelog_content = File.read(changelog_path)
    assert_includes changelog_content, "## [#{codelab_version}]",
                    "workshop/CODELAB_CHANGELOG.md must document current version [#{codelab_version}]"

    assert_match(/<!-- 🏷️ Codelab Version: #{Regexp.escape(codelab_version)} -->/, @codelab,
                 "Top comment in workshop/CODELAB.md must match workshop/CODELAB_VERSION (#{codelab_version})")

    last_page = @codelab.split(/^## 🎓 Conclusion & Clean Up/).last.to_s
    assert_match(/\*Codelab Version: v#{Regexp.escape(codelab_version)}\b.*workshop\/CODELAB_CHANGELOG\.md.*\*/, last_page,
                 "Last page of workshop/CODELAB.md must contain small-italic Codelab Version v#{codelab_version} footer")

    if File.exist?(DEVSITE_LAB_PATH)
      devsite_content = File.read(DEVSITE_LAB_PATH)
      assert_match(/\*Codelab Version: v#{Regexp.escape(codelab_version)}\b.*workshop\/CODELAB_CHANGELOG\.md.*\*/, devsite_content,
                   "DevSite index.lab.md must also contain the synced small-italic Codelab Version v#{codelab_version} footer")
      refute_match(/<details>|<summary>/, devsite_content,
                   "DevSite index.lab.md must not contain raw <details> or <summary> HTML tags (fixes M3)")
    end
  end

  def test_no_internal_google_paths_exfiltrated
    forbidden_prefix = ["/google", "src/"].join("/")
    files = `git -C #{REPO_ROOT} ls-files`.lines.map(&:strip)
    offending = files.reject { |f| %w[AGENTS.md GEMINI.md CLAUDE.md test/test_codelab_sync_and_contracts.rb].include?(f) }.select do |rel|
      full = File.join(REPO_ROOT, rel)
      File.file?(full) && File.read(full, encoding: "BINARY").include?(forbidden_prefix)
    end
    assert_empty offending, "Public repository MUST NOT contain internal #{forbidden_prefix} references! Found in: #{offending.join(', ')}"
  end

  # =========================================================================
  # 8. Constitution §11: Zero Gemini API Keys (100% Vertex AI with ADC)
  # =========================================================================
  def test_constitution_bans_gemini_api_key_and_enforces_vertex_ai_adc
    constitution = File.read(File.join(REPO_ROOT, "docs/CONSTITUTION.md"))
    assert_match(/Zero Gemini API Keys/i, constitution,
                 "docs/CONSTITUTION.md must codify Core Principle #11: Zero Gemini API Keys (100% Vertex AI with ADC)")

    forbidden_files = %w[
      .env.dist
      blog/compose.yaml
      blog/compose.prod.yaml
      blog/lib/nanobanana.rb
      blog/app/controllers/statuses_controller.rb
      blog/app/views/workshop/alerts/_ai_status.html.erb
      workshop/CODELAB.md
      workshop/SKELETON.md
      workshop/skeleton.yaml
    ]

    forbidden_files.each do |rel_path|
      full = File.join(REPO_ROOT, rel_path)
      next unless File.exist?(full)
      content = File.read(full)
      refute_match(/\bGEMINI_API_KEY\b/, content,
                   "#{rel_path} MUST NOT reference GEMINI_API_KEY (violates Constitution §11 — use Vertex AI via ADC)")
    end
  end

  # =========================================================================
  # 9. REQ-10 (Septober #175): Zero Personal Emails in Public Configs/Tests
  # =========================================================================
  def test_no_personal_emails_in_public_configs_or_tests
    personal_emails = %w[
      ricc@google.com
      emiliano.dellacasa@gmail.com
      palladiusbonton@gmail.com
      riccardo.carlesso@gmail.com
      riccardo.and.kate@gmail.com
      rubycon.italy@gmail.com
    ]
    pattern = Regexp.union(personal_emails)

    tracked = `git -C #{REPO_ROOT} ls-files '*.json' '*.yml' '*.yaml' '.env.dist' 'justfile' 'bin/*' 'blog/db/*' 'blog/test/*' 'test/*'`.lines.map(&:strip)
    tracked.reject! { |f| f == "test/test_codelab_sync_and_contracts.rb" }

    offending = tracked.select do |rel_path|
      full = File.join(REPO_ROOT, rel_path)
      File.file?(full) && File.binread(full).force_encoding("UTF-8").scrub("").match?(pattern)
    end

    assert_empty offending,
                 "Public config/JSON/YAML/test files MUST NOT expose personal email addresses (#{personal_emails.join(', ')})! Found in: #{offending.join(', ')}"
  end

  # =========================================================================
  # 10. Constitution §12: Harness-Agnostic Agent Instructions
  # =========================================================================
  def test_harness_instruction_files_are_symlinks_to_agents_md
    %w[GEMINI.md CLAUDE.md].each do |name|
      path = File.join(REPO_ROOT, name)
      assert File.symlink?(path), "#{name} must be a symlink, never a copy (Constitution §12)"
      assert_equal "AGENTS.md", File.readlink(path), "#{name} must point to AGENTS.md"
    end
  end

  def test_harness_skill_directories_are_symlinks_to_skills
    %w[.claude/skills .agents/skills].each do |rel|
      path = File.join(REPO_ROOT, rel)
      assert File.symlink?(path), "#{rel} must be a symlink to skills/ (Constitution §12)"
      assert_equal File.realpath(File.join(REPO_ROOT, "skills")), File.realpath(path),
                   "#{rel} must resolve to the repository's skills/ directory"
    end
  end

  # =========================================================================
  # 11. DevSite sync must not drop metadata that exists only on the destination
  # =========================================================================
  def test_sync_preserves_destination_only_step_metadata_and_frontmatter
    require "tmpdir"
    require "open3"

    Dir.mktmpdir do |dir|
      dest = File.join(dir, "index.lab.md")
      File.write(dest, <<~MD)
        ---
        id: example-codelab
        ---

        # Rails 8 on Google Cloud: From Zero to AI

        ## Introduction
        Duration: 05:00

        Stale introduction text.

        ## Step 0: An older title for this step
        Duration: 10:00

        Destination_Only_Flag: True

        Stale step text.
      MD

      2.times do |run|
        _out, err, status = Open3.capture3({ "DEVSITE_CODELAB_PATH" => dest }, "ruby",
                                           File.join(REPO_ROOT, "bin", "sync_devsite_codelab.rb"))
        assert status.success?, "sync run #{run + 1} failed: #{err}"

        synced = File.read(dest)
        assert synced.start_with?("---\nid: example-codelab\n---\n"), "destination frontmatter must survive a sync"
        refute_includes synced, "Stale step text.", "the body must be replaced by CODELAB.md"

        step0 = synced[/^## Step 0:.*?(?=^## Step 1:)/m]
        refute_nil step0, "synced file must contain Step 0 followed by Step 1"
        assert_equal 1, step0.scan("Destination_Only_Flag: True").size,
                     "run #{run + 1}: the destination-only line must stay under Step 0, exactly once"
        assert_equal 1, synced.scan("Destination_Only_Flag: True").size,
                     "run #{run + 1}: the destination-only line must not leak into other steps"
        assert_operator step0.index("Destination_Only_Flag: True"), :<, step0.index("### 1. Prerequisites Checklist"),
                        "the destination-only line must sit before the step's first sub-heading"
        refute_includes step0, "Duration: 10:00", "a key the source already states must not be duplicated"
      end
    end
  end
end



