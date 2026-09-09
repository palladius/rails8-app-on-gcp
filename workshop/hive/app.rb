# frozen_string_literal: true

require "sinatra/base"
require "json"
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
      authorizer = ServiceAccountLoader.load_authorizer
      entries = SheetsReader.fetch_entries(credentials: authorizer)

      {
        status: "ok",
        total_students: entries.size,
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


      # Esegui il check asincrono / parallelo via thread
      checks = Healthchecker.check_all(urls)

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

