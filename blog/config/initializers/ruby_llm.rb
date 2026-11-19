# frozen_string_literal: true

# RubyLLM talks to Vertex AI with Application Default Credentials only
# (Constitution §11): the attached service account on Cloud Run,
# `gcloud auth application-default login` on a laptop. No API keys.
# Used by SemanticSearch (lib/semantic_search.rb) for embeddings and RAG answers.
RubyLLM.configure do |config|
  config.vertexai_project_id = ENV["GOOGLE_CLOUD_PROJECT"]
  config.vertexai_location   = ENV.fetch("GOOGLE_CLOUD_LOCATION", "global")
  config.request_timeout     = 30
  config.max_retries         = 1
  config.logger              = Rails.logger
end
