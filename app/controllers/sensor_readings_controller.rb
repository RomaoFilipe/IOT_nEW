# app/controllers/sensor_readings_controller.rb
class SensorReadingsController < ApplicationController
  def new
    @reading = SensorReading.new(read_at: Time.current)
    @sensors = Sensor.select(:id,:name)
  end

  def create
    @reading = SensorReading.new(sr_params)
    if @reading.save
      redirect_to analytics_path(production_kind: params[:production_kind] || "agriculture"),
                  notice: "Leitura registada."
    else
      @sensors = Sensor.select(:id,:name)
      flash.now[:alert] = "Verifica os campos."
      render :new, status: :unprocessable_entity
    end
  end

  private

  def sr_params
    params.require(:sensor_reading).permit(
      :sensor_id, :read_at,
      :moisture, :temperature, :battery, :signal,
      :light_intensity, :wind_speed, :wind_direction,
      :air_temperature, :air_humidity,
      :soil_ph, :soil_ec, :soil_nitrogen, :soil_potassium, :soil_phosphorus
    )
  end
end
