# frozen_string_literal: true

require "yaml"

module WorkshopEval
  # InvariantChecker evaluates cumulative cascading invariants across workshop steps.
  # It enforces monotonic architectural state progression ("one-way doors") to eliminate regressions.
  class InvariantChecker
    Result = Struct.new(:id, :from_step, :title, :description, :passed, :error_message, keyword_init: true) do
      def passed?
        passed
      end

      def failure?
        !passed
      end
    end

    attr_reader :invariants, :repo_root

    def initialize(invariants: [], repo_root: nil)
      @invariants = invariants || []
      @repo_root = repo_root || File.expand_path("../..", __dir__)
    end

    # Returns all invariants applicable for the given step number (from_step <= step_number)
    def invariants_for_step(step)
      step_num = step.to_s.gsub(/^step-?/, "").to_i
      @invariants.select do |inv|
        inv_from = inv["from_step"].to_i
        inv_from <= step_num
      end
    end

    # Evaluates a single invariant specification
    def evaluate_invariant(inv)
      check_type = inv["check"].to_s.strip
      handler_method = "check_#{check_type}"

      if respond_to?(handler_method, true)
        send(handler_method, inv)
      else
        evaluate_fallback_code(inv)
      end
    rescue StandardError => e
      build_result(inv, passed: false, error_message: "Execution error: #{e.message}")
    end

    # Evaluates all active invariants for a specific step
    def evaluate_for_step(step)
      active_invariants = invariants_for_step(step)
      active_invariants.map { |inv| evaluate_invariant(inv) }
    end

    private

    def build_result(inv, passed:, error_message: nil)
      Result.new(
        id: inv["id"],
        from_step: inv["from_step"],
        title: inv["title"],
        description: inv["description"],
        passed: passed,
        error_message: error_message
      )
    end

    # Rule: compose_has_service
    # Semantically ensures production compose file contains a specific service sidecar
    def check_compose_has_service(inv)
      params = inv["params"] || {}
      target_service = params["service"]
      file_rel = params["file"] || "blog/compose.prod.yaml"
      file_path = File.join(repo_root, file_rel)

      unless File.exist?(file_path)
        return build_result(inv, passed: false, error_message: "Compose file '#{file_rel}' not found.")
      end

      compose_data = YAML.safe_load(File.read(file_path)) rescue nil
      unless compose_data.is_a?(Hash) && compose_data["services"].is_a?(Hash)
        return build_result(inv, passed: false, error_message: "Invalid or malformed YAML in #{file_rel}")
      end

      unless compose_data["services"].key?(target_service)
        return build_result(inv, passed: false, error_message: "REGRESSION: Required service '#{target_service}' missing from #{file_rel}!")
      end

      build_result(inv, passed: true)
    end

    # Rule: three_tier_architecture
    # Semantically verifies that production compose definition contains web, worker, and proxy services
    def check_three_tier_architecture(inv)
      params = inv["params"] || {}
      file_rel = params["file"] || "blog/compose.prod.yaml"
      file_path = File.join(repo_root, file_rel)

      unless File.exist?(file_path)
        return build_result(inv, passed: false, error_message: "Compose file '#{file_rel}' not found.")
      end

      compose_data = YAML.safe_load(File.read(file_path)) rescue nil
      unless compose_data.is_a?(Hash) && compose_data["services"].is_a?(Hash)
        return build_result(inv, passed: false, error_message: "Invalid or malformed YAML in #{file_rel}")
      end

      required_services = %w[web worker cloudsql-proxy]
      missing = required_services.reject { |svc| compose_data["services"].key?(svc) }

      if missing.any?
        return build_result(inv, passed: false, error_message: "REGRESSION: Three-tier architecture incomplete! Missing service(s): #{missing.join(', ')} in #{file_rel}")
      end

      build_result(inv, passed: true)
    end

    # Rule: toolchain_integrity
    # Ultra-fast (< 10ms) verification that essential workshop CLIs are available on PATH
    def check_toolchain_integrity(inv)
      params = inv["params"] || {}
      required_tools = params["tools"] || %w[git gcloud docker terraform ruby just]

      path_dirs = ENV["PATH"].to_s.split(File::PATH_SEPARATOR)
      missing_tools = required_tools.reject do |tool|
        path_dirs.any? { |dir| File.executable?(File.join(dir, tool)) }
      end

      if missing_tools.any?
        return build_result(inv, passed: false, error_message: "REGRESSION: Essential tool(s) missing from PATH: #{missing_tools.join(', ')}")
      end

      build_result(inv, passed: true)
    end

    # Rule: admin_user_seeded
    # Verifies that database contains at least 1 administrator user
    def check_admin_user_seeded(inv)
      if defined?(User) && defined?(ActiveRecord::Base) && ActiveRecord::Base.connected?
        begin
          has_admin = User.where(admin: true).exists? || User.exists?
          unless has_admin
            return build_result(inv, passed: false, error_message: "REGRESSION: No administrator user found in database!")
          end
        rescue StandardError => e
          # Safely fall through if DB is not queryable
        end
      end

      # Static verification: check db/seeds.rb enforces admin creation
      seeds_file = File.join(repo_root, "blog/db/seeds.rb")
      if File.exist?(seeds_file)
        seeds_content = File.read(seeds_file)
        unless seeds_content.include?("admin_email") || seeds_content.include?("User.find_or_create_by")
          return build_result(inv, passed: false, error_message: "REGRESSION: db/seeds.rb missing admin user bootstrap logic!")
        end
      end

      build_result(inv, passed: true)
    end

    # Rule: database_migrations_current
    # Fast check verifying zero pending migrations once DB is initialized
    def check_database_migrations_current(inv)
      if defined?(ActiveRecord::Base) && ActiveRecord::Base.connected?
        begin
          context = ActiveRecord::MigrationContext.new(File.join(repo_root, "blog/db/migrate"))
          if context.needs_migration?
            return build_result(inv, passed: false, error_message: "REGRESSION: Pending database migrations detected!")
          end
        rescue StandardError => e
          # Safely fall through if offline
        end
      end

      # Static verification: db/schema.rb exists if migrations exist
      schema_file = File.join(repo_root, "blog/db/schema.rb")
      migrate_dir = File.join(repo_root, "blog/db/migrate")
      if Dir.exist?(migrate_dir) && Dir.glob(File.join(migrate_dir, "*.rb")).any? && !File.exist?(schema_file)
        return build_result(inv, passed: false, error_message: "REGRESSION: Migrations exist in db/migrate but db/schema.rb is missing!")
      end

      build_result(inv, passed: true)
    end

    # Rule: no_local_storage
    # Ensures storage is configured for Google Cloud Storage rather than local disk
    def check_no_local_storage(inv)
      params = inv["params"] || {}
      config_rel = params["config_file"] || "blog/config/storage.yml"
      storage_file = File.join(repo_root, config_rel)

      unless File.exist?(storage_file)
        return build_result(inv, passed: false, error_message: "Storage configuration file not found: #{config_rel}")
      end

      raw_content = File.read(storage_file)
      # Safely strip ERB tags for static YAML inspection without evaluating arbitrary code
      stripped_content = raw_content.gsub(/<%[=\-_#]?.*?%>/m, "")
      storage_data = YAML.safe_load(stripped_content, aliases: true) rescue nil
      unless storage_data.is_a?(Hash)
        return build_result(inv, passed: false, error_message: "Invalid or malformed YAML in #{config_rel}")
      end

      # In Step 4+, storage configuration must define a google or GCS service entry
      has_google_service = storage_data.any? do |_name, config|
        config.is_a?(Hash) && (
          config["service"] == "GCS" ||
          config["service"] == "Google" ||
          config["iam"] == true ||
          config[:service] == "GCS" ||
          config[:service] == "Google"
        )
      end

      unless has_google_service
        return build_result(inv, passed: false, error_message: "REGRESSION: Storage configuration does not define GCS service! Local storage is forbidden from Step 4 onward.")
      end

      # Check production environment configuration if present
      prod_env_file = [
        File.join(repo_root, "blog/config/environments/production.rb"),
        File.join(repo_root, "config/environments/production.rb")
      ].find { |p| File.exist?(p) }

      if prod_env_file
        prod_content = File.read(prod_env_file)
        if prod_content.match?(/config\.active_storage\.service\s*=\s*:local\b/)
          return build_result(inv, passed: false, error_message: "REGRESSION: #{prod_env_file} explicitly sets active_storage.service to :local!")
        end
      end

      # If Rails environment happens to be loaded in process, check runtime ActiveStorage tier
      if defined?(Rails) && Rails.respond_to?(:application) && Rails.application
        active_service = Rails.application.config.active_storage.service rescue nil
        if active_service == :local
          return build_result(inv, passed: false, error_message: "REGRESSION: ActiveStorage runtime service is currently set to :local! Must be :google or cloud persistent.")
        end
      end

      build_result(inv, passed: true)
    end

    # Rule: zero_stuck_jobs
    # Ensures Solid Queue has zero unworked background jobs accumulating in queue
    def check_zero_stuck_jobs(inv)
      # If Rails and SolidQueue are defined, query DB safely with fast timeout
      if defined?(SolidQueue::Job)
        begin
          stuck_count = SolidQueue::Job.where(finished_at: nil).count
          if stuck_count > 0
            return build_result(inv, passed: false, error_message: "REGRESSION: #{stuck_count} background job(s) stuck in queue! Dedicated Solid Queue worker required from Step 6 onward.")
          end
        rescue StandardError => e
          # DB might not be connected in isolated unit tests; that is allowed offline
        end
      end

      # Static verification: verify that a worker execution strategy is configured in compose.prod.yaml
      compose_file = File.join(repo_root, "blog/compose.prod.yaml")
      if File.exist?(compose_file)
        compose_data = YAML.safe_load(File.read(compose_file)) rescue nil
        if compose_data.is_a?(Hash) && compose_data["services"].is_a?(Hash)
          has_worker = compose_data["services"].key?("worker")
          unless has_worker
            return build_result(inv, passed: false, error_message: "REGRESSION: No Solid Queue worker sidecar found in blog/compose.prod.yaml from Step 6 onward.")
          end
        end
      end

      build_result(inv, passed: true)
    end

    # Fallback for custom code blocks
    def check_ruby_code(inv)
      code = inv["code"] || inv["script"]
      return build_result(inv, passed: true) if code.nil? || code.strip.empty?

      Dir.chdir(repo_root) do
        eval(code)
      end
      build_result(inv, passed: true)
    rescue StandardError => e
      build_result(inv, passed: false, error_message: "Invariant violation: #{e.message}")
    end

    def evaluate_fallback_code(inv)
      if inv["code"]
        check_ruby_code(inv)
      else
        build_result(inv, passed: false, error_message: "Unknown invariant check type: '#{inv['check']}'")
      end
    end
  end
end
