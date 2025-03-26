class DashboardController < ApplicationController
  before_action :authenticate_user! # Garante que apenas utilizadores logados acedem
  def index
  end
end
