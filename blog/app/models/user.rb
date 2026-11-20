class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :posts, dependent: :nullify

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # The workshop admin is the account db/seeds.rb creates at every boot of the web container, with
  # the same environment variables. With none of them set, nobody is admin.
  def self.admin_email
    %w[GOOGLE_CLOUD_ACCOUNT GOOGLE_CLOUD_EMAIL ADMIN_EMAIL].filter_map { |key| ENV[key].presence }.first&.strip&.downcase
  end

  def admin?
    admin_email = User.admin_email
    admin_email.present? && email_address == admin_email
  end

  # Gravatar avatar URL based on email hash
  def gravatar_url(size: 80)
    hash = Digest::MD5.hexdigest(email_address.strip.downcase)
    "https://www.gravatar.com/avatar/#{hash}?s=#{size}&d=retro"
  end
end
