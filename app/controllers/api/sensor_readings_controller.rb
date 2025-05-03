# app/controllers/api/sensor_readings_controller.rb
module Api
  class SensorReadingsController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      sensor = Sensor.find(params[:id])

      reading = sensor.sensor_readings.create!(
        temperature: params[:temperature],
        moisture: params[:moisture],
        battery: params[:battery],
        signal: params[:signal],
        read_at: params[:read_at] || Time.current
      )

      # Atualizar o sensor com os dados mais recentes
      sensor.update!(
        temperature: reading.temperature,
        moisture: reading.moisture,
        last_value: params[:value],
        battery: reading.battery,
        signal: reading.signal,
        last_reading: reading.read_at
      )

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "overview-#{sensor.field_id}",
            partial: "fields/tabs/overview",
            locals: { field: sensor.field }
          )
        end

        format.json { render json: { status: "ok", reading: reading } }
      end
    rescue => e
      render json: { error: e.message }, status: 400
    end
  end
end
