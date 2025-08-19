# app/controllers/aquaculture_readings_controller.rb
class AquacultureReadingsController < ApplicationController
  def new
    @reading = AquacultureReading.new(measured_at: Time.current)
    @fields  = Field.select(:id,:name).where(production_kind: %w[aquaculture_sea aquaculture_tank])
  end

  def create
    @reading = AquacultureReading.new(reading_params)
    if @reading.save
      redirect_to analytics_path(production_kind: params[:production_kind] || "aquaculture_sea"),
                  notice: "Leitura registada com sucesso."
    else
      @fields = Field.select(:id,:name).where(production_kind: %w[aquaculture_sea aquaculture_tank])
      flash.now[:alert] = "Verifica os campos."
      render :new, status: :unprocessable_entity
    end
  end

  private

  def reading_params
    params.require(:aquaculture_reading).permit(
      :field_id, :measured_at, :temperature, :ph, :salinity, :oxygen_level
    )
  end
end
