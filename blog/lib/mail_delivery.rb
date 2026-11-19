# Configures Action Mailer delivery from environment variables.
#
# With SMTP_HOST set, mail is sent over SMTP (SMTP_PORT defaults to 587;
# SMTP_USERNAME and SMTP_PASSWORD are optional). Without it, deliveries are
# skipped: mail jobs complete and Rails logs the mail instead of trying to
# reach an SMTP server on localhost:25.
#
# APP_HOST sets the host used for links in mail (e.g. password reset links).
module MailDelivery
  DEFAULT_SMTP_PORT = 587
  DEFAULT_HOST = "example.com"

  def self.configure(mailer_config, env = ENV)
    mailer_config.default_url_options = { host: env["APP_HOST"].presence || DEFAULT_HOST }

    smtp_host = env["SMTP_HOST"].presence
    unless smtp_host
      mailer_config.perform_deliveries = false
      return mailer_config
    end

    username = env["SMTP_USERNAME"].presence
    mailer_config.delivery_method = :smtp
    mailer_config.perform_deliveries = true
    mailer_config.smtp_settings = {
      address: smtp_host,
      port: Integer(env["SMTP_PORT"].presence || DEFAULT_SMTP_PORT),
      user_name: username,
      password: env["SMTP_PASSWORD"].presence,
      authentication: (:plain if username)
    }.compact
    mailer_config
  end
end
