class ProfilesController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update]

  def show
    @user = User.find(params[:id]) # Certifique-se de que o ID do usuário é passado corretamente
  end

  def edit; end

  def update
    if @user.update(profile_params)
      redirect_to profile_path(@user), notice: 'Perfil atualizado com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
  end

  def profile_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :photo)
  end
end
