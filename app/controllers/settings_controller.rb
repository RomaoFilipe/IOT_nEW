class SettingsController < ApplicationController
  before_action :set_user

  def index
    # Renderiza a view index.html.erb
  end

  def update_profile
    if @user.update(user_params)
      redirect_to settings_path, notice: "Perfil atualizado com sucesso."
    else
      redirect_to settings_path, alert: "Erro ao atualizar perfil."
    end
  end

  def update_notifications
    @user.update(
      notif_email: params[:notif_email].present?,
      notif_sms: params[:notif_sms].present?
    )
    redirect_to settings_path, notice: "Notificações atualizadas."
  end

  def update_password
    if @user.update(password: params[:password])
      redirect_to settings_path, notice: "Password atualizada com sucesso."
    else
      redirect_to settings_path, alert: "Erro ao atualizar password."
    end
  end

  # ✅ Atualiza o idioma via sessão e redireciona de volta
  def locale
    locale = params[:locale]

    if I18n.available_locales.map(&:to_s).include?(locale)
      session[:locale] = locale
      I18n.locale = locale
    end

    redirect_back fallback_location: root_path(locale: I18n.locale)
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:name, :email)
  end
end
