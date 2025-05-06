module Api
  class SensorReadingsController < BaseController
    before_action :authenticate_api!
    before_action :set_sensor

    def create
  
        Rails.logger.info "🛰️ Recebida leitura: #{params.inspect}"
      
        @sensor.sensor_readings.create!(
          temperature: params[:temperature],
          moisture: params[:moisture],
          battery: params[:battery],
          signal: params[:signal],
          read_at: Time.at(params[:timestamp])  # ← Corrigido!
        )
      render json: { status: "created" }, status: :created
    end

    private

    def set_sensor
      @sensor = Sensor.find(params[:id])
    end
  end
end
