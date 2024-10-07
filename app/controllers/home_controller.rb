class HomeController < ApplicationController
  before_action :authenticate_user!  # Garante que o usuário esteja autenticado
  def index
  end
end
