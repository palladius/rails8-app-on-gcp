# frozen_string_literal: true

require "sinatra/base"
require "json"

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
      { status: "ok", service: "workshop-hive", timestamp: Time.now.utc.iso8601 }.to_json
    end
  end
end
