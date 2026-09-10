# frozen_string_literal: true

class BoomsController < ApplicationController
  allow_unauthenticated_access only: [:show]

  def show
    raise RuntimeError, "💥 Deliberate Boom: Verifying Google Cloud Error Reporting & Structured Logging!"
  end
end
