# frozen_string_literal: true

require "test_helper"

class UncheckedInPodcastifierPedagogyTest < ActiveSupport::TestCase
  test "canonical codebase on main must NOT have hardcoded podcastifier implementation" do
    # 1. Ensure routes do not contain generate_podcast action
    routes_content = File.read(Rails.root.join("config/routes.rb"))
    assert_no_match(/generate_podcast/, routes_content, "routes.rb must not pre-wire generate_podcast; attendees build it as a Step 7 exercise")

    # 2. Ensure posts controller does not have generate_podcast method
    controller_content = File.read(Rails.root.join("app/controllers/posts_controller.rb"))
    assert_no_match(/def generate_podcast/, controller_content, "PostsController must not include generate_podcast in the base codebase")

    # 3. Ensure posts view does not pre-render the generate podcast button
    show_view_content = File.read(Rails.root.join("app/views/posts/show.html.erb"))
    assert_no_match(/Generate Audio Podcast|generate_podcast/, show_view_content, "posts/show.html.erb must not pre-render podcast button")

    # 4. Ensure no dedicated cloud_tts_service is checked in to main
    assert_not File.exist?(Rails.root.join("lib/cloud_tts_service.rb")), "cloud_tts_service.rb must live in solutions/podcastifier branch, not main"
    assert_not File.exist?(Rails.root.join("app/services/cloud_tts_service.rb")), "app/services must stay empty"

    # 5. Ensure PodcastifierJob exists as an unfinished student stub containing COMPLETE_ME
    job_file = Rails.root.join("app/jobs/podcastifier_job.rb")
    assert File.exist?(job_file), "podcastifier_job.rb should exist as a scaffold stub"
    job_content = File.read(job_file)
    assert_includes job_content, "COMPLETE_ME", "podcastifier_job.rb must contain 'COMPLETE_ME' placeholder before attendee implements it"
    assert_operator job_content.lines.count, :<=, 8, "podcastifier_job.rb must be a tiny scaffold stub (<= 8 lines on main, > 10 lines once implemented)"

    # 6. Ensure the canonical TTS voice 'it-IT-Wavenet-A' is not implemented/hardcoded anywhere in app/ or lib/ on main
    app_and_lib_files = Dir.glob(Rails.root.join("{app,lib}/**/*.{rb,erb}"))
    app_and_lib_files.each do |f|
      content = File.read(f)
      # We allow the comment in the job stub, but no actual implementation
      next if f.end_with?("podcastifier_job.rb")
      assert_no_match(/it-IT-Wavenet-A/, content, "Canonical voice 'it-IT-Wavenet-A' must NOT be hardcoded in #{f}; students implement it in Step 7")
    end
  end
end
