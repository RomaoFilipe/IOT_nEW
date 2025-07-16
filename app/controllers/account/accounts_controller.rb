# app/controllers/account/accounts_controller.rb
class Account::AccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_account
  before_action :authorize_account_access!

  def edit; end

  def update
    if @account.update(account_params)
      redirect_to edit_account_account_path, notice: "Conta atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_account
    @account = current_user.account
  end

  def authorize_account_access!
    return if current_user.owner?
    return if current_user.admin? && current_user.account == @account

    redirect_to root_path, alert: "Acesso negado."
  end

  def account_params
    params.require(:account).permit(:name, :farm_type)
  end
end
