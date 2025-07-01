class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin_or_owner!
  before_action :set_user, only: [:edit, :update, :destroy]

  def edit; end

  def update
    if @user.update(user_params)
      redirect_to admin_accounts_path, notice: "Utilizador atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    redirect_to admin_accounts_path, notice: "Utilizador removido com sucesso."
  end

  private

  def set_user
    if current_user.owner?
      @user = User.find(params[:id])
    else
      @user = current_user.account.users.find_by(id: params[:id])
      redirect_to root_path, alert: "Acesso não autorizado." unless @user
    end
  end

  def user_params
    permitted = [:name, :email, :role, :password, :password_confirmation]
    permitted << :account_id if current_user.owner?
    params.require(:user).permit(permitted)
  end

  def authorize_admin_or_owner!
    unless current_user.role.in?(%w[admin owner])
      redirect_to root_path, alert: "Acesso não autorizado."
    end
  end
end
