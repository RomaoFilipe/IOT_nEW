# frozen_string_literal: true
module Api
  class SensorReadingsController < BaseController
    before_action :authenticate_api!
    before_action :normalize_payload!
    before_action :set_sensor!

    # Aceita:
    # - { device_id: "...", data: { temp_c:, hum_air:, soil_raw:, soil_pct:, lux:, ... } }
    # - { sensor_id: 123, temperature:, moisture:, air_humidity:, light_intensity:, ... }
    def create
      Rails.logger.info "🛰️ Recebida leitura normalizada: #{ @payload.inspect }"

      # 1) alinhar sensor_type/STI opcionalmente se vier no payload
      if (wanted = @payload[:sensor_type]).present?
        normalized = case wanted.to_s.downcase
                     when "temperatura" then "temperature"
                     when "humidade"    then "moisture"
                     else wanted.to_s.downcase
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

      # 2) timestamp
      read_time =
        begin
          ts = @payload[:timestamp]
          ts.present? ? Time.at(ts.to_f) : Time.current
        rescue
          Time.current
        end

      # 3) criar leitura (mapeando chaves que possam ter vindo “no estilo IoT”)
      reading_attrs = {
        temperature:     @payload[:temperature],      # genérico (°C solo/dispositivo)
        moisture:        @payload[:moisture],         # genérico (% solo)
        battery:         @payload[:battery],
        signal:          @payload[:signal],
        light_intensity: @payload[:light_intensity],  # lux
        wind_speed:      @payload[:wind_speed],
        wind_direction:  @payload[:wind_direction],
        air_temperature: @payload[:air_temperature],
        air_humidity:    @payload[:air_humidity],
        soil_ph:         @payload[:soil_ph],
        soil_ec:         @payload[:soil_ec],
        soil_nitrogen:   @payload[:soil_nitrogen],
        soil_potassium:  @payload[:soil_potassium],
        soil_phosphorus: @payload[:soil_phosphorus],
        uptime:          @payload[:uptime],
        error_count:     @payload[:error_count],
        read_at:         read_time
      }.compact

      @sensor.sensor_readings.create!(reading_attrs)

      # 4) atualizar “estado” do sensor para cartões de overview
      @sensor.update(
        battery:      @payload[:battery],
        signal:       @payload[:signal],
        temperature:  @payload[:temperature],
        moisture:     @payload[:moisture],
        last_reading: Time.current,
        status:       "Active"
      )

      render json: { status: "created" }, status: :created
    end

    private

    # Desaninha params[:data] e faz o “mapa” das chaves do dispositivo → app
    def normalize_payload!
      raw = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h

      # 1) desaninhado
      base = raw["data"].is_a?(Hash) ? raw["data"] : raw
      base = base.deep_symbolize_keys

      # 2) mapear nomes comuns vindos do firmware
      mapped = {
        # higrow / sensores comuns
        temperature:      base[:temperature] || base[:temp] || base[:temp_c],
        moisture:         base[:moisture]    || base[:soil_pct],
        air_humidity:     base[:air_humidity]|| base[:hum_air],
        air_temperature:  base[:air_temperature] || base[:temp_air] || base[:t_air],
        light_intensity:  base[:light_intensity] || base[:lux],
        soil_ph:          base[:soil_ph],
        soil_ec:          base[:soil_ec],
        soil_nitrogen:    base[:soil_nitrogen],
        soil_potassium:   base[:soil_potassium],
        soil_phosphorus:  base[:soil_phosphorus],
        battery:          base[:battery],
        signal:           base[:signal],
        uptime:           base[:uptime],
        error_count:      base[:error_count],
        sensor_type:      base[:sensor_type],
        timestamp:        base[:timestamp]
      }.compact

      # 3) guardar para o resto do fluxo
      @device_id = raw["device_id"] || base[:device_id]
      @payload   = mapped
    end

    def set_sensor!
      @sensor =
        if params[:sensor_id].present?
          Sensor.find(params[:sensor_id])
        elsif params[:id].present?
          # quando a rota é /api/sensors/:id/readings
          Sensor.find(params[:id])
        elsif @device_id.present?
          Sensor.find_by!(device_id: @device_id)
        else
          raise ActiveRecord::RecordNotFound, "Sem sensor_id nem device_id"
        end
    end
  end
end
