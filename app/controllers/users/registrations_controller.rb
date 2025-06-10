module Users
  class RegistrationsController < Devise::RegistrationsController
    def create
      nif = sign_up_params[:company_nif]
      account = find_or_create_account(nif)

      build_resource(sign_up_params.except(:company_nif))
      resource.account = account
      resource.status = "active"

      if resource.save
        yield resource if block_given?
        sign_up(resource_name, resource)
        redirect_to dashboard_path
      else
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    end

    private

    def sign_up_params
      params.require(:user).permit(
        :name, :email, :password, :password_confirmation,
        :role, :status, :photo, :notif_email, :notif_sms, :company_nif
      )
    end

    def find_or_create_account(nif)
      Account.find_or_create_by(nif: nif) do |acc|
        acc.name = "#{params[:user][:name]} Empresa"
        acc.farm_type = "agriculture"  # podes adaptar depois
      end
    end
  end
end
