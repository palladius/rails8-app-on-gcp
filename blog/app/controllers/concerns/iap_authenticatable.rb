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

    # Defense-in-depth: check against application-level allowlist if defined
    unless allowed_iap_user?(iap_email)
      Rails.logger.warn "[IAP] Access denied for #{iap_email}: not in IAP_ALLOWED_USERS list."
      flash.now[:alert] = "⛔ Access Denied: #{iap_email} is not in the IAP allowlist."
      return
    end

    # If already authenticated as this user in the current session, do nothing
    if Current.session&.user&.email_address == iap_email
      return
    end


    # Auto-find or create the user with a secure random password
    is_new = false
    user = User.find_by(email_address: iap_email)
    unless user
      user = User.create!(
        email_address: iap_email,
        password: SecureRandom.hex(16),
        created_via: "iap",
        description: "Auto-generated as logged in from IAP allow listed users"
      )

      is_new = true
    end


    start_new_session_for(user)

    if is_new
      flash.now[:notice] = "🛡️ Login recognized by IAP -> User ##{user.id} (#{user.email_address}) just created!"
    else
      flash.now[:notice] = "🛡️ Login recognized by IAP -> User ##{user.id} (#{user.email_address})"
    end
  end

  def allowed_iap_user?(email)
    raw_allowed = ENV["IAP_ALLOWED_USERS"]
    return true if raw_allowed.blank?

    allowed_list = raw_allowed.to_s.split(",").map(&:strip).map(&:downcase).reject(&:blank?)
    allowed_list.include?(email.downcase)
  end
end


