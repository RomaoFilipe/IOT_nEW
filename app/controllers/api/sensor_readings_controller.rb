# app/controllers/api/sensor_readings_controller.rb
module Api
  class SensorReadingsController < BaseController
    before_action :authenticate_api!
    before_action :set_sensor

    def create
      Rails.logger.info "🛰️ Recebida leitura: #{params.inspect}"

      # ── 1) Se vier sensor_type na leitura, alinhar tipo e STI ───────────────────
      if params[:sensor_type].present?
        wanted = params[:sensor_type].to_s.downcase

        # normalizar PT -> EN para consistência
        normalized = case wanted
                     when "temperatura" then "temperature"
                     when "humidade"    then "moisture"
                     else wanted
                     end

        expected_type = case normalized
                        when "temperature", "moisture" then "TemperatureSensor"
                        when "irrigation"              then "IrrigationSensor"
                        else "Sensor"
                        end

        if @sensor.sensor_type != normalized || @sensor.type != expected_type
          @sensor.update(sensor_type: normalized, type: expected_type)
        end
      end

      # ── 2) Preparar timestamp da leitura ────────────────────────────────────────
      read_time =
        begin
          ts = params[:timestamp]
          ts.present? ? Time.at(ts.to_f) : Time.current
        rescue
          Time.current
        end

      # ── 3) Criar leitura ───────────────────────────────────────────────────────
      @sensor.sensor_readings.create!(
        temperature:      params[:temperature],
        moisture:         params[:moisture],
        battery:          params[:battery],
        signal:           params[:signal],
        light_intensity:  params[:light_intensity],
        wind_speed:       params[:wind_speed],
        wind_direction:   params[:wind_direction],
        air_temperature:  params[:air_temperature],
        air_humidity:     params[:air_humidity],
        soil_ph:          params[:soil_ph],
        soil_ec:          params[:soil_ec],
        soil_nitrogen:    params[:soil_nitrogen],
        soil_potassium:   params[:soil_potassium],
        soil_phosphorus:  params[:soil_phosphorus],
        uptime:           params[:uptime],
        error_count:      params[:error_count],
        read_at:          read_time
      )

      # ── 4) Atualizar “estado” do sensor ────────────────────────────────────────
      @sensor.update(
        battery:      params[:battery],
        signal:       params[:signal],
        temperature:  params[:temperature],
        moisture:     params[:moisture],
        last_reading: Time.current,
        status:       "Active"
      )

      render json: { status: "created" }, status: :created
    end

    private

    def set_sensor
      @sensor = Sensor.find(params[:sensor_id] || params[:id])
    end
  end
end
