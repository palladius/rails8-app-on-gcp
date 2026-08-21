# frozen_string_literal: true

# Guards config/storage.yml against the two regressions behind issue #8:
#
#   1. signing blob URLs with a private key, which Cloud Run does not have
#      (the metadata server only hands out access tokens) -> every blob 500s;
#   2. "fixing" that by making the buckets public, which iac/AGENTS.md forbids
#      ("Use ActiveStorage with private access to images and media").
#
# This test parses storage.yml on its own instead of requiring test_helper, so
# it runs without booting Rails or decrypting credentials:
#   bin/rails test test/config/storage_config_test.rb
require "minitest/autorun"
require "erb"
require "pathname"
require "yaml"

class StorageConfigTest < Minitest::Test
  STORAGE_YML = Pathname.new(File.expand_path("../../config/storage.yml", __dir__))
  GCS_SERVICES = %w[google_dev google_test google_prod].freeze
  FAKE_PROJECT = "fake-gcp-project"
  SA_EMAIL_FORMAT = /\A[^@\s]+@[^@\s]+\.iam\.gserviceaccount\.com\z/

  def setup
    @config = load_storage_config
  end

  def test_every_environment_has_its_own_gcs_service
    assert_equal GCS_SERVICES.sort, (@config.keys & GCS_SERVICES).sort,
      "storage.yml must define one GCS service per environment"
  end

  def test_gcs_buckets_are_namespaced_per_environment
    GCS_SERVICES.each do |name|
      env = name.delete_prefix("google_")
      assert_equal "#{FAKE_PROJECT}-activestorage-#{env}", @config[name]["bucket"],
        "#{name} must point at the #{env} bucket of the current GCP project"
      assert_equal FAKE_PROJECT, @config[name]["project"]
    end
  end

  def test_gcs_services_sign_urls_through_the_iam_credentials_api
    GCS_SERVICES.each do |name|
      assert_equal true, @config[name]["iam"],
        "#{name} must set `iam: true`: Cloud Run has no private key, so ActiveStorage " \
        "has to sign blob URLs via the IAM Credentials signBlob API (issue #8)"
    end
  end

  def test_gcs_services_name_the_service_account_that_signs
    GCS_SERVICES.each do |name|
      assert_match SA_EMAIL_FORMAT, @config[name]["gsa_email"].to_s,
        "#{name} must name the signer service account, so signing also works off " \
        "Cloud Run, where there is no metadata server to ask"
    end
  end

  def test_gcs_services_are_never_public
    GCS_SERVICES.each do |name|
      refute @config[name]["public"],
        "#{name} must not be public: blobs stay private and are served through " \
        "expiring signed URLs (see iac/AGENTS.md)"
    end
  end

  # storage.yml's ERB reaches for Rails.root (the Disk services) and for
  # Rails.env / Rails.application.credentials (the commented-out S3 example, which
  # ERB evaluates even though YAML ignores it), so a minimal stand-in is enough to
  # render the file without a booted app.
  module RailsStub
    CREDENTIALS = Object.new
    def CREDENTIALS.dig(*) = nil

    APPLICATION = Object.new
    def APPLICATION.credentials = CREDENTIALS

    def self.root
      Pathname.new(File.expand_path("../..", __dir__))
    end

    def self.env
      "test"
    end

    def self.application
      APPLICATION
    end
  end

  private
    def load_storage_config
      Object.const_set(:Rails, RailsStub) unless defined?(Rails)

      with_env("GOOGLE_CLOUD_PROJECT" => FAKE_PROJECT, "GCS_SIGNER_SA_EMAIL" => nil) do
        YAML.safe_load(ERB.new(STORAGE_YML.read).result, aliases: true)
      end
    end

    def with_env(vars)
      previous = ENV.to_hash.slice(*vars.keys)
      vars.each { |key, value| ENV[key] = value }
      yield
    ensure
      vars.each_key { |key| ENV[key] = previous[key] }
    end
end
