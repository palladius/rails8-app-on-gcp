# frozen_string_literal: true

# GET /boom raises on purpose so you can watch Google Cloud Error Reporting catch and group a
# production crash (workshop Step 8, Quest 2).
#
# Only the workshop admin may trigger it: the account db/seeds.rb creates from GOOGLE_CLOUD_ACCOUNT
# (or ADMIN_EMAIL). A public crash button would let anyone flood Error Reporting, its notifications
# and the log bill. Anonymous visitors are sent to the sign-in page; other users get a plain 404.
class BoomsController < ApplicationController
  # A dedicated class, so the test crash gets its own, clearly named group in Error Reporting.
  class DeliberateBoom < StandardError; end

  before_action :require_admin

  def show
    Rails.logger.warn("Deliberate test exception requested by admin user ##{Current.user.id}")
    raise DeliberateBoom, "💥 Deliberate Boom: Verifying Google Cloud Error Reporting & Structured Logging!"
  end

  private
    def require_admin
      head :not_found unless Current.user&.admin?
    end
end
