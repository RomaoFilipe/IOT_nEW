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
        light_intensity: params[:light_intensity],
        wind_speed: params[:wind_speed],
        wind_direction: params[:wind_direction],
        air_temperature: params[:air_temperature],
        air_humidity: params[:air_humidity],
        soil_ph: params[:soil_ph],
        soil_ec: params[:soil_ec],
        soil_nitrogen: params[:soil_nitrogen],
        soil_potassium: params[:soil_potassium],
        soil_phosphorus: params[:soil_phosphorus],
        uptime: params[:uptime],
        error_count: params[:error_count],
        read_at: Time.at(params[:timestamp])
      )

      # Atualizar status do sensor (última leitura)
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
