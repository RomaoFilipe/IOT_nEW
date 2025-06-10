class Admin::AccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_owner!

  def index
    @accounts = Account.all
  end

  def show
    @account = Account.find(params[:id])
    @users = @account.users
  end

  private

  def authorize_owner!
    redirect_to root_path, alert: "Acesso negado." unless current_user.owner?
  end
end
