class SettingsController < ApplicationController
  before_action :set_user

  def index
    # Apenas renderiza a view index.html.erb
  end

  def update_profile
    if @user.update(user_params)
      redirect_to settings_path, notice: "Perfil atualizado com sucesso."
    else
      redirect_to settings_path, alert: "Erro ao atualizar perfil."
    end
  end

  def update_notifications
    # Exemplo simples de flags de notificações
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

    def locale
    session[:locale] = params[:locale]
    redirect_back fallback_location: root_path
  end

  private

  def set_user
    @user = current_user # Adaptar ao teu sistema de autenticação
  end

  def user_params
    params.require(:user).permit(:name, :email)
  end
end
