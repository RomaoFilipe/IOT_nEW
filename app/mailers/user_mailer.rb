class UserMailer < ApplicationMailer
  default from: "no-reply@iotagro.pt"

  def welcome_email(user, generated_password)
    @user = user
    @generated_password = generated_password
    @login_url = "https://iotagro.pt/users/sign_in"
    @account = @user.account
    @company_name = @account&.name || "Empresa"
    @company_nif = @account&.nif || "N/A"

    mail(
      to: @user.email,
      subject: "👋 Bem-vindo à IoT Agro - A tua conta foi criada"
    )
  end
end
