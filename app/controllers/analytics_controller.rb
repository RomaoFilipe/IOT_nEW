class AnalyticsController < ApplicationController
  layout 'application'  # Garante que o layout application seja usado
  def index
    @crop_yields = CropYield.order(:id)
  end
end
