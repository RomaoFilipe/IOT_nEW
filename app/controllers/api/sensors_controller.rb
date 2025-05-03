# ✅ 1. Atualizar o controller da API
# app/controllers/api/sensors_controller.rb
module Api
  class SensorsController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :authenticate_api!

    def simulate
      sensor = Sensor.find(params[:id])

      sensor.update(
        last_value: params[:value] || "#{rand(10..90)}%",
        battery: params[:battery] || rand(60..100),
        signal: params[:signal] || rand(60..100),
        temperature: params[:temperature] || rand(10..35),
        moisture: params[:moisture] || rand(30..90),
        last_reading: Time.current
      )


      render json: { status: "ok", sensor: sensor }
    end

    def toggle_status
      @sensor = Sensor.find(params[:id])
      @sensor.update(status: @sensor.status == "Active" ? "Inactive" : "Active")
    
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "sensor_row_#{@sensor.id}",
            partial: "sensors/row",
            locals: { sensor: @sensor }
          )
        end
        format.html { redirect_back fallback_location: fields_path, notice: "Sensor atualizado." }
      end
    end
    

    private

    def authenticate_api!
      token = request.headers["Authorization"]
      expected = "Bearer #{ENV.fetch("API_TOKEN")}"
    
      head :unauthorized unless token == expected
    end
  end
end
