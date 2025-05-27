class SoilReadingsController < ApplicationController
  def create
    @soil_reading = SoilReading.new(soil_reading_params)
    if @soil_reading.save
      redirect_back fallback_location: fields_path, notice: "Leitura do solo registada com sucesso."
    else
      redirect_back fallback_location: fields_path, alert: "Erro ao registar leitura do solo."
    end
  end

  private

  def soil_reading_params
    params.require(:soil_reading).permit(:field_id, :moisture, :ph, :nitrogen, :measured_at)
  end
end
