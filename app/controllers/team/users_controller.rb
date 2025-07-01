class Team::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin_or_manager
  before_action :set_user, only: [:edit, :update, :destroy, :impersonate]
  before_action :set_account, only: [:index, :update_account]

  def index
    @users = current_user.account.users.order(:name)
  end

  def new
    @user = current_user.account.users.new
  end

  def create
    @user = current_user.account.users.new(user_params)
    @user.status = "active"

    if @user.save
      redirect_to team_users_path, notice: "Utilizador criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @user.update(user_params)
      redirect_to team_users_path, notice: "Utilizador atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to team_users_path, alert: "Não podes remover-te a ti mesmo."
    else
      @user.destroy
      redirect_to team_users_path, notice: "Utilizador removido com sucesso."
    end
  end

  def update_account
    if @account.update(account_params)
      redirect_to team_users_path, notice: "Nome da empresa atualizado com sucesso."
    else
      redirect_to team_users_path, alert: "Erro ao atualizar o nome da empresa."
    end
  end

  def impersonate
    session[:owner_user_id] = current_user.id
    sign_in(@user)
    redirect_to dashboard_path, notice: "Agora estás a simular o utilizador #{@user.name}."
  end

  def revert_impersonation
    original_user = User.find_by(id: session[:owner_user_id])
    if original_user
      sign_in(original_user)
      session.delete(:owner_user_id)
      redirect_to team_users_path, notice: "Regressaste ao teu utilizador original."
    else
      redirect_to root_path, alert: "Erro ao reverter simulação."
    end
  end

  private

  def ensure_admin_or_manager
    redirect_to root_path, alert: "Acesso não autorizado." unless current_user.admin? || current_user.manager?
  end

  def set_user
    @user = current_user.account.users.find_by(id: params[:id])
    redirect_to team_users_path, alert: "Utilizador não encontrado." if @user.nil?
  end

  def set_account
    @account = current_user.account
  end

  def account_params
    params.require(:account).permit(:name, :farm_type)
  end

  def user_params
    params.require(:user).permit(
      :name,
      :email,
      :password,
      :password_confirmation,
      :role,
      :photo,
      :notif_email,
      :notif_sms
    )
  end
end
