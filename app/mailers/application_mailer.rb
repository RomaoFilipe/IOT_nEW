class ApplicationMailer < ActionMailer::Base
  default from: -> { default_from }
  layout "mailer"

  private

  def default_from
    Rails.application.credentials.dig(:smtp, :from) ||
      ENV["SMTP_FROM"] ||
      "no-reply@#{Rails.application.credentials.dig(:smtp, :domain) || 'example.com'}"
  end
end
