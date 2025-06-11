class Team::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin_or_manager
  before_action :set_user, only: [:destroy, :impersonate]

  def index
    @users = current_user.account.users.order(:created_at)
  end

  def new
    @user = User.new
  end

def edit
  @user = current_user.account.users.find(params[:id])
end

  def create
    @user = User.new(user_params)
    @user.account = current_user.account
    @user.status = "active"

    if @user.save
      redirect_to team_users_path, notice: "Utilizador criado com sucesso."
    else
      render :new, status: :unprocessable_entity
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
    unless current_user.admin? || current_user.manager?
      redirect_to root_path, alert: "Acesso não autorizado."
    end
  end

  def authorize_admin_or_manager!
    unless current_user.admin? || current_user.manager?
      redirect_to root_path, alert: "Não tens permissão para aceder a esta página."
    end
  end

  def set_user
    @user = current_user.account.users.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to team_users_path, alert: "Utilizador não encontrado."
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role, :photo)
  end
end
