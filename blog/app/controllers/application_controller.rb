class ApplicationController < ActionController::Base
  include Authentication
  include IapAuthenticatable
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  rescue_from Propshaft::MissingAssetError do |exception|
    Rails.logger.warn("[Propshaft] Rescued missing asset error: #{exception.message}")
    if request.format.html?
      render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
    else
      head :not_found
    end
  end
end
