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

    get "/" do
      send_file File.join(settings.public_folder, "index.html")
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

