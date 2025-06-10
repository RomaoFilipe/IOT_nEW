class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user

  # 🔐 Lista geral de utilizadores (usado por admins)
  def index
    @users = User.all
    authorize User
  end

  # ➕ Novo utilizador
  def new
    @user = User.new
    authorize @user
  end

  # 💾 Criar utilizador
  def create
    @user = User.new(user_params)
    authorize @user

    if @user.save
      redirect_to users_path, notice: "Utilizador criado com sucesso!"
    else
      render :new, alert: "Erro ao criar o utilizador."
    end
  end

  # ✏️ Editar utilizador
  def edit
    @user = User.find(params[:id])
    authorize @user
  end

  # 💾 Atualizar utilizador
  def update
    @user = User.find(params[:id])
    authorize @user

    if @user.update(user_params)
      redirect_to users_path, notice: "Utilizador atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # 👥 Entrar como outro utilizador (modo simulação)
  def entrar_como
    user = User.find(params[:id])
    authorize user, :entrar_como?

    session[:admin_user_id] = current_user.id
    sign_in(user, bypass: true)

    redirect_to dashboard_path, notice: "Agora estás autenticado como #{user.name}."
  end

  # 🔙 Retornar ao modo original
  def retornar_como_admin
    admin_user = User.find(session[:admin_user_id])
    authorize admin_user, :retornar_como_admin?

    sign_in(admin_user, bypass: true)
    session.delete(:admin_user_id)

    redirect_to admin_accounts_path, notice: "Voltaste ao modo Owner."
  end

  # ❌ Eliminar utilizador
  def destroy
    user = User.find(params[:id])
    authorize user
    user.destroy

    redirect_to users_path, notice: "Utilizador removido com sucesso."
  end

  # 📊 Painel personalizado para admin (caso uses)
  def admin_dashboard
    authorize User
    @users = User.all
    render layout: "admin"
  end

  private

  # 🔐 Pundit (controle global)
  def authorize_user
    authorize User
  end

  # 🧾 Parâmetros permitidos
  def user_params
    params.require(:user).permit(
      :name, :email, :password, :password_confirmation,
      :role, :status, :photo, :notif_email, :notif_sms
    )
  end
end
