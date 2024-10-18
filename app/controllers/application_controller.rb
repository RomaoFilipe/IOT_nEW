class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :photo])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :photo])
  end
  # Redireciona para a página "home" após o login
  def after_sign_in_path_for(resource)
    home_path  # Redireciona para a página 'home' após o login
  end

  # Redireciona para a página de login após o logout
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path # Redireciona para a página de login do Devise
  end
end
