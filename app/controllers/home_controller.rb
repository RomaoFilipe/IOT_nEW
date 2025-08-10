class HomeController < ApplicationController
skip_before_action :authenticate_user!, only: [:index]

  def index
    # Lógica da página home
  end
end
