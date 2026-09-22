ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

# Ensure repo root .env is loaded when running commands directly from blog/
begin
  require "dotenv"
  Dotenv.load(File.expand_path("../../.env", __dir__))
rescue LoadError
  # Dotenv is only available in development/test
end
