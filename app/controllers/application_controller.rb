# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  # CSRF
  protect_from_forgery with: :exception

  # Devise: obriga login por padrão
  before_action :authenticate_user!

  # Pundit (use o módulo novo)
  include Pundit::Authorization
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Para as views
  helper_method :current_account

    # ——— Locale nas URLs (evita passar locale: ... em todos os links)
  def default_url_options
    { locale: I18n.locale }.compact
  end

  # ---- Navegação após login/logout (Devise)
  def after_sign_in_path_for(_resource)
    # Garante que a rota existe. Se não tiveres /home, troca por dashboard_path, por ex.
    home_path
  end

  def after_sign_out_path_for(_resource_or_scope)
    root_path
  end

  # ---- Tratamento de autorização (Pundit)
  def user_not_authorized
    redirect_to(root_path, alert: "Você não tem permissão para realizar esta ação.")
  end

  # ---- Conta atual (com “simulação” opcional)
  def current_account
    @current_account ||= begin
      if session[:simulated_account_id].present?
        Account.find_by(id: session[:simulated_account_id])
      else
        # current_user é de Devise; pode ser nil se removeres o before_action
        current_user&.account
      end
    end
  end
end
