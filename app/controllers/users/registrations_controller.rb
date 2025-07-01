class Users::RegistrationsController < Devise::RegistrationsController
  def new
    build_resource
    yield resource if block_given?
    respond_with resource
  end

  def create
    build_resource(sign_up_params)
    nif = params[:user][:company_nif]

    # Dono do site (owner) não precisa de NIF
    if resource.role == "owner" || nif.blank?
      resource.role = :owner
      resource.status = "active"
    else
      account = Account.find_by(nif: nif)

      if account
        # Se a conta já existir, associa o utilizador como viewer
        resource.account = account
        resource.role = :viewer
        resource.status = "active"
      else
        # Cria nova conta (primeiro registo com este NIF)
        account = Account.create!(
          name: "Empresa de #{resource.name}",
          nif: nif,
          farm_type: "agriculture" # podes personalizar
        )
        resource.account = account
        resource.role = :admin
        resource.status = "active"
      end
    end

    if resource.save
      yield resource if block_given?
      if resource.active_for_authentication?
        sign_up(resource_name, resource)
        redirect_to dashboard_path, notice: "Conta criada com sucesso."
      else
        expire_data_after_sign_in!
        redirect_to root_path, notice: "Conta criada. Verifica o teu email para ativar."
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource, status: :unprocessable_entity
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :company_nif, :photo)
  end
end
