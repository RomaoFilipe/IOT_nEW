class Users::SessionsController < Devise::SessionsController
  before_action :configure_sign_in_params, only: [:create]

  def create
    email = params[:user][:email].to_s.downcase.strip
    nif = params[:user][:company_nif].to_s.strip

    user = User.find_by(email: email)

    if user.nil?
      flash.now[:alert] = "Credenciais inválidas"
      return respond_with resource, location: new_session_path(resource_name)
    end

    if user.owner?
      # Dono da plataforma pode fazer login sem NIF
      super and return
    end

    if nif.blank?
      flash.now[:alert] = "É obrigatório introduzir o NIF da empresa"
      return respond_with resource, location: new_session_path(resource_name)
    end

    if user.account.nil? || user.account.nif != nif
      flash.now[:alert] = "NIF incorreto ou não corresponde à conta associada"
      return respond_with resource, location: new_session_path(resource_name)
    end

    # Se passou todas as validações, continuar com Devise login
    super
  end

  protected

  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:company_nif])
  end
end
