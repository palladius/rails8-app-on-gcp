# frozen_string_literal: true

require "sinatra/base"
require "json"

begin
  require "dotenv/load"
rescue LoadError
end
require_relative "lib/service_account_loader"
require_relative "lib/sheets_reader"
require_relative "lib/healthchecker"

module WorkshopHive
  class App < Sinatra::Base
    configure do
      set :public_folder, File.join(__dir__, "public")
      set :views, File.join(__dir__, "views")
      set :bind, "0.0.0.0"
      set :port, ENV.fetch("PORT", 8080).to_i
    end

    helpers do
      def build_index_json(params)
        max_age = params["max_age"]

        show_dupes = params.key?("show_duplicates_true") ||
                     params.key?("show_duplicatees_true") ||
                     ["true", "1", "yes"].include?(params["show_duplicates"].to_s.strip.downcase) ||
                     ["true", "1", "yes"].include?(params["show_duplicatees"].to_s.strip.downcase) ||
                     ["true", "1", "yes"].include?(params["show_duplicates_true"].to_s.strip.downcase) ||
                     ["true", "1", "yes"].include?(params["show_duplicatees_true"].to_s.strip.downcase)

        deduplicate = !show_dupes
        authorizer = ServiceAccountLoader.load_authorizer
        entries = SheetsReader.fetch_entries(credentials: authorizer, max_age: max_age, deduplicate: deduplicate)
        urls = entries.map { |e| e[:url] }
        checks = Healthchecker.get_or_refresh_async(urls)

        now = Time.now.utc
        event_name = params["event_name"] || ENV["HIVE_EVENT_NAME"] || "workshop-#{now.strftime('%Y%m%d')}"
        raw_start = params["event_start"] || ENV["HIVE_EVENT_START"]

        event_start =
          if raw_start && !raw_start.to_s.strip.empty?
            (Time.parse(raw_start.to_s) rescue nil)
          end

        elapsed_mins = event_start ? [0.0, ((now - event_start) / 60.0).round(1)].max : nil
        elapsed_hrs = elapsed_mins ? (elapsed_mins / 60.0).round(2) : nil
        coupon_hrs = (params["coupon_hours"] || ENV["COUPON_DURATION_HOURS"] || 12).to_f
        cinderella_expiry = event_start ? (event_start + (coupon_hrs * 3600)) : nil
        cinderella_hrs_left = cinderella_expiry ? [0.0, ((cinderella_expiry - now) / 3600.0).round(2)].max : nil

        version = (File.read(File.join(__dir__, "VERSION")).strip rescue "0.1.1")

        step_counts = Hash.new(0)
        total_up = 0

        items = entries.map do |entry|
          url = entry[:url].to_s.strip
          check = checks[url] || {}
          is_up = (check[:status] == "up")
          total_up += 1 if is_up
          tel = check[:telemetry] || {}
          step_num = tel[:step_number]
          step_counts["step_#{step_num}"] += 1 if step_num

          clean_url = url.sub(%r{/+$}, "")
          status_url = "#{clean_url}/status.json"
          up_url = "#{clean_url}/up"

          {
            nickname: entry[:nickname],
            url: url,
            status_url: status_url,
            up_url: up_url,
            status: check[:status] || "pending",
            http_code: check[:http_code],
            latency_ms: check[:latency_ms],
            step_number: tel[:step_number],
            step_description: tel[:step_description],
            db_tier: tel[:db_tier] || tel[:db_badge],
            db_badge: tel[:db_badge],
            storage_tier: tel[:storage_tier] || tel[:storage_badge],
            storage_badge: tel[:storage_badge],
            ai_badge: tel[:ai_badge],
            ruby_version: tel[:ruby_version],
            rails_version: tel[:rails_version],
            posts_count: tel[:posts_count],
            pending_jobs: tel[:pending_jobs],
            k_service: tel[:k_service],
            k_revision: tel[:k_revision],
            proctor_status: tel[:proctor_status],
            proctor_reviewer: tel[:proctor_reviewer],
            proctor_approved_at: tel[:proctor_approved_at],
            quest_ghi_issue: tel[:quest_ghi_issue],
            registered_at: entry[:timestamp],
            checked_at: check[:checked_at]
          }
        end

        step_8_winners = items.select { |it| it[:step_number] == 8 }.map do |it|
          won_at = it[:proctor_approved_at] || it[:checked_at] || it[:registered_at]
          {
            nickname: it[:nickname],
            url: it[:url],
            status_url: it[:status_url],
            won_at: won_at,
            proctor_reviewer: it[:proctor_reviewer],
            quest_ghi_issue: it[:quest_ghi_issue]
          }
        end.sort_by { |w| w[:won_at].to_s }

        step_8_podium = step_8_winners.each_with_index.map do |w, idx|
          rank = idx + 1
          medal = case rank
                  when 1 then "🥇"
                  when 2 then "🥈"
                  when 3 then "🥉"
                  else "🏆"
                  end
          w.merge(rank: rank, medal: medal)
        end

        {
          status: "ok",
          service: "workshop-hive",
          version: version,
          timestamp: now.iso8601,
          event: {
            name: event_name,
            started_at: event_start&.iso8601,
            elapsed_minutes: elapsed_mins,
            elapsed_hours: elapsed_hrs,
            coupon_duration_hours: coupon_hrs,
            cinderella_expiry_at: cinderella_expiry&.iso8601,
            cinderella_hours_remaining: cinderella_hrs_left
          },
          query_params: params,
          summary: {
            total_students: entries.size,
            total_up: total_up,
            step_distribution: step_counts,
            step_8_podium: step_8_podium
          },
          entries: items
        }
      end
    end

    get "/" do
      if request.accept?("application/json") && !request.accept?("text/html")
        content_type :json
        build_index_json(params).to_json
      else
        send_file File.join(settings.public_folder, "index.html")
      end
    end

    get "/index.json" do
      content_type :json
      build_index_json(params).to_json
    end

    get "/status.json" do
      content_type :json
      build_index_json(params).to_json
    end

    get "/metastatus.json" do
      content_type :json
      build_index_json(params).to_json
    end

    get "/up" do
      content_type :json
      {
        status: "ok",
        service: "workshop-hive",
        timestamp: Time.now.utc.iso8601
      }.to_json
    end

    get "/api/leaderboard" do
      content_type :json
      max_age = params["max_age"]

      # Support show_duplicates=true, show_duplicatees=true, show_duplicates_true, show_duplicatees_true, 1, yes
      show_dupes = params.key?("show_duplicates_true") ||
                   params.key?("show_duplicatees_true") ||
                   ["true", "1", "yes"].include?(params["show_duplicates"].to_s.strip.downcase) ||
                   ["true", "1", "yes"].include?(params["show_duplicatees"].to_s.strip.downcase) ||
                   ["true", "1", "yes"].include?(params["show_duplicates_true"].to_s.strip.downcase) ||
                   ["true", "1", "yes"].include?(params["show_duplicatees_true"].to_s.strip.downcase)

      deduplicate = !show_dupes
      authorizer = ServiceAccountLoader.load_authorizer
      entries = SheetsReader.fetch_entries(credentials: authorizer, max_age: max_age, deduplicate: deduplicate)

      {
        status: "ok",
        total_students: entries.size,
        max_age: max_age,
        show_duplicates: show_dupes,
        entries: entries,
        timestamp: Time.now.utc.iso8601
      }.to_json
    end

    get "/api/healthchecks" do
      content_type :json
      # Prendi gli URL correnti dagli entries registrati
      authorizer = ServiceAccountLoader.load_authorizer
      entries = SheetsReader.fetch_entries(credentials: authorizer)
      urls = entries.map { |e| e[:url] }

      # Ritorna SUBITO i dati cached e aggiorna in background (0ms latency al reload!)
      checks = Healthchecker.get_or_refresh_async(urls)

      {
        status: "ok",
        total_checked: checks.size,
        checks: checks,
        timestamp: Time.now.utc.iso8601
      }.to_json
    end
  end
end


WorkshopHive::App.run! if __FILE__ == $PROGRAM_NAME

