class Admin::AccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_owner!
  before_action :set_account, only: [:edit, :update, :destroy, :show]

  def index
    @accounts = Account.all.order(:created_at)
  end

  def new
    @account = Account.new
  end

  def create
    @account = Account.new(account_params)
    if @account.save
      redirect_to admin_accounts_path, notice: "Conta criada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

def update
  if @account.fields.exists? && params[:account][:farm_type] != @account.farm_type
    redirect_to admin_account_path(@account), alert: "⚠️ Não é possível alterar o tipo de produção com campos já existentes."
    return
  end

  if @account.update(account_params)
    redirect_to admin_account_path(@account), notice: "Conta atualizada com sucesso."
  else
    render :edit, status: :unprocessable_entity
  end
end

  def destroy
    @account.destroy
    redirect_to admin_accounts_path, notice: "Conta eliminada com sucesso."
  end

  private

  def authorize_owner!
    redirect_to root_path, alert: "Acesso negado." unless current_user.owner?
  end

  def set_account
    @account = Account.find(params[:id])
  end

  def account_params
    params.require(:account).permit(:name, :nif, :farm_type)
  end
end
