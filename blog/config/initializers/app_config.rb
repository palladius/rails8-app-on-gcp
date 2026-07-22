# App-wide configuration for links and metadata.
# Easy to change when URLs move around!
Rails.application.config.x.app = ActiveSupport::OrderedOptions.new
Rails.application.config.x.app.name = "Rails8 on GCP"
Rails.application.config.x.app.github_url = "https://github.com/palladius/rails8-app-on-gcp"
Rails.application.config.x.app.workshop_url = "https://github.com/palladius/rails8-app-on-gcp/blob/main/workshop/README.md"
