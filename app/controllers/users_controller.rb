class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :check_admin, only: [:index, :destroy]
  # Listagem de usuários, acessível apenas para administradores
  def index
    @users = User.all
  end

  def update
    @user = User.find(params[:id])

    if @user.update(user_params)
      redirect_to users_path, notice: 'Usuário atualizado com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def entrar_como
    user = User.find(params[:id])
    if current_user.admin?
      session[:admin_user_id] = current_user.id
      sign_in(user, bypass: true)
      redirect_to home_path, notice: "Agora você está logado como #{user.name}."
    else
      redirect_to root_path, alert: "Acesso negado."
    end
  end

  def retornar_como_admin
    admin_user = User.find(session[:admin_user_id])
    if admin_user&.admin?
      sign_in(admin_user, bypass: true)
      session.delete(:admin_user_id)
      redirect_to users_path, notice: "Você retornou ao modo administrador."
    else
      redirect_to root_path, alert: "Acesso negado."
    end
  end

  def destroy
    user = User.find(params[:id])
    user.destroy
    redirect_to users_path, notice: 'Usuário excluído com sucesso.'
  end

  private

  # Método para verificar se o usuário atual é administrador
  def check_admin
    redirect_to root_path, alert: 'Acesso negado.' unless current_user&.admin?
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
