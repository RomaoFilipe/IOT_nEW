# app/controllers/team/users_controller.rb
class Team::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin_or_manager
  before_action :set_account, only: [:index, :update_account]
  before_action :set_user, only: [:edit, :update, :destroy, :impersonate]

  # Lista de utilizadores + cartão de edição da conta
  def index
    @users = current_user.account.users.order(:name)
  end

  # Formulário de novo utilizador
  def new
    @user = current_user.account.users.new
  end

  # Criação (com convite opcional)
  def create
    @user = current_user.account.users.new(user_params)
    # Validação de papel permitido pela hierarquia
    unless role_allowed_for_current?(user_params[:role])
      return redirect_to new_team_user_path, alert: "Não tens permissão para atribuir esse papel."
    end

    # Se não vier password, gera uma para convite
    generated_password = nil
    if @user.password.blank?
      generated_password = Devise.friendly_token.first(12)
      @user.password = generated_password
      @user.password_confirmation = generated_password
    end

    @user.status = "active" if @user.respond_to?(:status) && @user.status.blank?

    if @user.save
      # Envio de e-mail de boas-vindas + password (se aplicável e notificação por email ativa)
      if @user.try(:notif_email) && defined?(UserMailer)
        begin
          UserMailer.welcome_email(@user, generated_password).deliver_later
        rescue => e
          Rails.logger.warn("[Users#create] Falhou envio do email de boas-vindas: #{e.message}")
        end
      end
      msg = "Utilizador criado com sucesso"
      msg += @user.try(:notif_email) ? " e notificado por email." : "."
      redirect_to team_users_path, notice: msg
    else
      render :new, status: :unprocessable_entity
    end
  end

  # Editar
  def edit
  end

  # Atualizar (respeita hierarquia)
  def update
    if current_user.manager? && (@user.admin? || @user.owner?)
      return redirect_to team_users_path, alert: "Gestores não podem alterar administradores/owners."
    end

    if user_params[:role].present? && !role_allowed_for_current?(user_params[:role])
      return redirect_to edit_team_user_path(@user), alert: "Não tens permissão para atribuir esse papel."
    end

    if @user.update(user_params.compact_blank)
      redirect_to team_users_path, notice: "Dados do utilizador atualizados com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Remover
  def destroy
    if @user == current_user
      return redirect_to team_users_path, alert: "Não podes remover o teu próprio utilizador."
    end
    if current_user.manager? && (@user.admin? || @user.owner?)
      return redirect_to team_users_path, alert: "Gestores não têm permissão para remover administradores/owners."
    end

    @user.destroy
    redirect_to team_users_path, notice: "Utilizador eliminado com sucesso."
  end

  # Atualizar dados da conta (nome + production_kind)
  def update_account
    # Bloqueia alterar o tipo de produção se já existir pelo menos um campo
    has_fields = @account.respond_to?(:fields) && @account.fields.exists?

    if has_fields && account_params[:production_kind].present? &&
       account_params[:production_kind] != @account.production_kind
      flash[:alert] = "❌ Não é possível alterar o tipo de produção com campos já criados."
      return redirect_to team_users_path
    end

    if @account.update(account_params)
      redirect_to team_users_path, notice: "Dados da empresa atualizados com sucesso."
    else
      redirect_to team_users_path, alert: "Erro ao atualizar os dados da empresa."
    end
  end

  # Simular utilizador
  def impersonate
    unless can_impersonate?(current_user, @user)
      return redirect_to team_users_path, alert: "Não tens permissão para simular este utilizador."
    end

    session[:owner_user_id] = current_user.id
    sign_in(@user)
    redirect_to dashboard_path, notice: "Agora estás a simular o utilizador #{@user.name}."
  end

  # Reverter simulação
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

  # --- Autorização de acesso à secção ---
  def ensure_admin_or_manager
    unless current_user.admin? || current_user.manager? || current_user.owner?
      redirect_to root_path, alert: "Acesso não autorizado."
    end
  end

  # --- Conta/Utilizador ---
  def set_account
    @account = current_user.account
  end

  def set_user
    @user = current_user.account.users.find_by(id: params[:id])
    return redirect_to team_users_path, alert: "Utilizador não encontrado." unless @user
  end

  # --- Strong params ---
  def account_params
    params.require(:account).permit(:name, :production_kind)
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

  # --- Hierarquia e simulação ---
  # owner > admin > manager > technician > viewer
  def role_order
    %w[owner admin manager technician viewer]
  end

  def role_allowed_for_current?(target_role)
    return true if target_role.blank?

    current_idx = role_order.index(current_user.role.to_s)
    target_idx  = role_order.index(target_role.to_s)
    return false if current_idx.nil? || target_idx.nil?

    # Só podes criar/atribuir papéis com índice >= ao teu (menos poder ou igual).
    # Dono pode tudo, admin não pode criar owner, manager não pode criar admin/owner.
    return true if current_user.owner?
    return (target_role != "owner") if current_user.admin?
    return !%w[admin owner].include?(target_role) if current_user.manager?
    false
  end

  def can_impersonate?(from_user, target_user)
    # Só se o teu poder for superior ao do alvo
    role_order.index(from_user.role) < role_order.index(target_user.role)
  end
end
