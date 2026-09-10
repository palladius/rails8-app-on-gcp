namespace :screenshots do
  desc "Capture declarative workshop screenshots intelligently (skips existing unless FORCE=true, supports FILTER=step-2)"
  task :generate do
    repo_root = Rails.root.join("..").to_s
    runner_script = File.join(repo_root, "workshop/screenshots/runner.js")
    filter = ENV["FILTER"] || ""
    force = ENV["FORCE"] == "true" || ENV["FORCE"] == "1"

    cmd = ["node", runner_script]
    cmd << filter unless filter.empty?
    cmd << "--force" if force

    puts "📸 [rake screenshots:generate] Executing declarative screenshot manager..."
    puts "   Filter: #{filter.empty? ? 'ALL' : filter}"
    puts "   Force overwrite: #{force}"

    system(*cmd, chdir: repo_root) || abort("Failed to generate screenshots")
  end

  desc "Validate declared screenshot specifications without server (dry-run)"
  task :check do
    repo_root = Rails.root.join("..").to_s
    runner_script = File.join(repo_root, "workshop/screenshots/runner.js")
    system("node", runner_script, "--dry-run", chdir: repo_root) || abort("Screenshot validation failed")
  end
end
