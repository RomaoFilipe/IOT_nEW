module Api
  class SensorReadingsController < BaseController
    before_action :authenticate_api!
    before_action :set_sensor

    def create
      Rails.logger.info "🛰️ Recebida leitura: #{params.inspect}"

      # Permitir leitura mesmo se estiver inativo, e ativar automaticamente
      @sensor.sensor_readings.create!(
        temperature: params[:temperature],
        moisture: params[:moisture],
        battery: params[:battery],
        signal: params[:signal],
        read_at: Time.at(params[:timestamp])
      )

      @sensor.update(
        battery: params[:battery],
        signal: params[:signal],
        temperature: params[:temperature],
        moisture: params[:moisture],
        last_reading: Time.current,
        status: "Active"
      )

      render json: { status: "created" }, status: :created
    end

    private

    def set_sensor
      @sensor = Sensor.find(params[:sensor_id] || params[:id])
    end
  end
end
