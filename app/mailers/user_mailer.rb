class UserMailer < ApplicationMailer
  def welcome_email(user, raw_password = nil)
    @user     = user
    @account  = user.account
    @app_name = Rails.application.class.module_parent_name
    @raw_password = raw_password

    I18n.with_locale(@user.try(:locale).presence || I18n.locale) do
      mail(
        to: @user.email,
        subject: I18n.t("mailers.user_mailer.welcome.subject", app: @app_name)
      )
    end
  end
end
