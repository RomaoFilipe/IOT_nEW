class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user

  def new
    @user = User.new
  end
  
  def index
    @users = User.all
    authorize User # Pundit verifica permissões
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to users_path, notice: 'Usuário criado com sucesso!'
    else
      render :new, alert: 'Erro ao criar o usuário.'
    end
  end

  def edit
    @user = User.find(params[:id])
    authorize @user
  end

  def update
    @user = User.find(params[:id])
    authorize @user
    if @user.update(user_params)
      redirect_to users_path, notice: 'Usuário atualizado com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def entrar_como
    user = User.find(params[:id])
    authorize user, :entrar_como? # Permissão específica para Admin
    session[:admin_user_id] = current_user.id
    sign_in(user, bypass: true)
    redirect_to home_path, notice: "Agora você está logado como #{user.name}."
  end

  def retornar_como_admin
    admin_user = User.find(session[:admin_user_id])
    authorize admin_user, :retornar_como_admin? # Apenas Admin pode retornar
    sign_in(admin_user, bypass: true)
    session.delete(:admin_user_id)
    redirect_to users_path, notice: "Você retornou ao modo administrador."
  end

  def destroy
    user = User.find(params[:id])
    authorize user
    user.destroy
    redirect_to users_path, notice: 'Usuário excluído com sucesso.'
  end

  private

  def authorize_user
    authorize User
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role, :status)
  end
end
