# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  include Pundit::Authorization
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :current_account

  before_action :set_locale
  # Só exige login quando NÃO for pedido público
  before_action :authenticate_user!, unless: :public_request?

  # URLs sempre com locale
  def default_url_options
    { locale: I18n.locale }.compact
  end

  # Devise
  def after_sign_in_path_for(_resource)
    home_path(locale: I18n.locale)
  end

  def after_sign_out_path_for(_resource_or_scope)
    root_path(locale: I18n.locale)
  end

  private

  # pedidos que NÃO exigem login
  def public_request?
    # controladores do Devise OU o trocar-idioma OU páginas públicas (ajusta à tua app)
    devise_controller? ||
      (controller_name == 'locales' && action_name == 'update') ||
      controller_path.in?(%w[home pages])
  end

  def set_locale
    allowed = I18n.available_locales.map(&:to_s)
    I18n.locale =
      if params[:locale].present? && allowed.include?(params[:locale])
        session[:locale] = params[:locale]
      else
        session[:locale].presence_in(allowed) || I18n.default_locale
      end
  end

  def user_not_authorized
    redirect_to(root_path(locale: I18n.locale), alert: "Você não tem permissão para realizar esta ação.")
  end

  def current_account
    @current_account ||= begin
      if session[:simulated_account_id].present?
        Account.find_by(id: session[:simulated_account_id])
      else
        current_user&.account
      end
    end
  end
end
