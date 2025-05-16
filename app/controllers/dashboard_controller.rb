class DashboardController < ApplicationController
  before_action :authenticate_user! # Garante que apenas utilizadores logados acedem
  def index
    @fields = Field.all
    @field = params[:field_id] ? Field.find(params[:field_id]) : Field.first
    @fields = Field.includes(:sensors, :crop_yields)
    @recommendations = Recommendation.where(dismissed: false).order(suggested_for: :asc).limit(5)
  end
  
end
