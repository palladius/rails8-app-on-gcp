class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :posts, dependent: :nullify

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address, presence: true, uniqueness: { case_sensitive: false, allow_blank: true }

  # Gravatar avatar URL based on email hash
  def gravatar_url(size: 80)
    hash = Digest::MD5.hexdigest(email_address.to_s.strip.downcase)
    "https://www.gravatar.com/avatar/#{hash}?s=#{size}&d=retro"
  end
end
