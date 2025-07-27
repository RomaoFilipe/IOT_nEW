class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  helper SensorsHelper
  include Pundit

  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

def set_locale
  if params[:locale].present?
    I18n.locale = params[:locale]
    session[:locale] = params[:locale]
  elsif session[:locale].present?
    I18n.locale = session[:locale]
  else
    I18n.locale = I18n.default_locale
  end
end


  def default_url_options
    { locale: I18n.locale }
  end

  protected

  def configure_permitted_parameters
    permitted = [:name, :photo, :role, :company_nif]
    devise_parameter_sanitizer.permit(:sign_up, keys: permitted)
    devise_parameter_sanitizer.permit(:account_update, keys: permitted)
  end

def after_sign_in_path_for(resource)
  home_path(locale: I18n.locale)
end

def after_sign_out_path_for(resource_or_scope)
  root_path(locale: I18n.locale)
end

  def user_not_authorized
    redirect_to root_path, alert: 'Você não tem permissão para realizar esta ação.'
  end

  def current_account
    if session[:simulated_account_id]
      Account.find(session[:simulated_account_id])
    else
      current_user.account
    end
  end
  helper_method :current_account
end
