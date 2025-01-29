class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  include Pundit

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :photo, :role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :photo, :role])
  end

  def after_sign_in_path_for(resource)
    home_path
  end

  def user_not_authorized
    redirect_to root_path, alert: 'Você não tem permissão para realizar esta ação.'
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end
end
