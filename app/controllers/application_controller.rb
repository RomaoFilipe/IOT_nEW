class ApplicationController < ActionController::Base
  # Redireciona para a página "home" após o login
  def after_sign_in_path_for(resource)
    home_path # Redireciona para /home
  end

  # Redireciona para a página de login após o logout
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path # Redireciona para a página de login do Devise
  end
end
