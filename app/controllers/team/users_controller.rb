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
  generated_password = Devise.friendly_token.first(12)
  @user.password = generated_password
  @user.status = "active"

  if @user.save
    if @user.notif_email?
      UserMailer.welcome_email(@user, generated_password).deliver_later
    end
    redirect_to team_users_path, notice: "Utilizador criado com sucesso#{@user.notif_email? ? ' e notificado por email.' : '.'}"
  else
    render :new, status: :unprocessable_entity
  end
end


  def edit; end

  def update
    if current_user.manager? && @user.admin?
      return redirect_to team_users_path, alert: "Gestores não têm permissões suficientes para modificar utilizadores com cargos superiores."
    end

    if @user.update(user_params)
      redirect_to team_users_path, notice: "Dados do utilizador atualizados com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to team_users_path, alert: "Não é possível remover o teu próprio utilizador."
    elsif current_user.manager? && @user.admin?
      redirect_to team_users_path, alert: "Gestores não têm permissões suficientes para remover administradores."
    else
      @user.destroy
      redirect_to team_users_path, notice: "Utilizador eliminado com sucesso."
    end
  end

  def update_account
    if @account.fields.any? && account_params[:farm_type] != @account.farm_type
      flash[:alert] = "❌ Não é possível alterar o tipo de exploração com campos já criados."
      return redirect_to team_users_path
    end

    if @account.update(account_params)
      redirect_to team_users_path, notice: "Dados da empresa atualizados com sucesso."
    else
      redirect_to team_users_path, alert: "Erro ao atualizar os dados da empresa."
    end
  end

  def impersonate
    if !can_impersonate?(current_user, @user)
      return redirect_to team_users_path, alert: "Não tens permissão para simular este utilizador."
    end

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

  def set_user
    @user = current_user.account.users.find_by(id: params[:id])
    redirect_to team_users_path, alert: "Utilizador não encontrado." and return if @user.nil?

    if current_user.manager? && @user.admin?
      redirect_to team_users_path, alert: "Gestores não têm permissões suficientes para modificar administradores." and return
    end
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

  # 🔒 Hierarquia: owner > admin > manager > technician > viewer
  def can_impersonate?(from_user, target_user)
    role_order = %w[owner admin manager technician viewer]
    role_order.index(from_user.role) < role_order.index(target_user.role)
  end
end
