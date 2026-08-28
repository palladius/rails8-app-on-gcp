module IapAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_via_iap, prepend: true
  end

  private

  def authenticate_via_iap
    raw_header = request.headers["X-Goog-Authenticated-User-Email"]
    # Allow local/test simulation via ENV
    if raw_header.blank? && (Rails.env.development? || Rails.env.test?) && ENV["IAP_MOCK_EMAIL"].present?
      raw_header = ENV["IAP_MOCK_EMAIL"]
    end
    return if raw_header.blank?

    # IAP sends format: 'accounts.google.com:user@gmail.com' or raw 'user@gmail.com'
    iap_email = raw_header.to_s.sub(/^accounts\.google\.com:/i, "").strip.downcase
    return if iap_email.blank?

    # If already authenticated as this user in the current session, do nothing
    if Current.session&.user&.email_address == iap_email
      return
    end

    # Auto-find or create the user with a secure random password
    user = User.find_or_create_by!(email_address: iap_email) do |u|
      u.password = SecureRandom.hex(16)
    end

    start_new_session_for(user)
  end
end
