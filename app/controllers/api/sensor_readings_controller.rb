# frozen_string_literal: true
module Api
  class SensorReadingsController < BaseController
    before_action :authenticate_api!
    before_action :normalize_payload!
    before_action :set_sensor!

    # Aceita:
    # - { device_id: "...", data: { temp_c:, hum_air:, soil_raw:, soil_pct:, lux:, battery_pct:, wifi_rssi:, ... } }
    # - { sensor_id: 123, temperature:, moisture:, air_humidity:, light_intensity:, battery:, signal:, ... }
    # - Rotas: /api/sensors/:id/readings  ou  /sensors/:id/readings  (conforme o teu routes)
    def create
      Rails.logger.info "🛰️ Recebida leitura normalizada: #{@payload.inspect}"

      # 1) Opcional: alinhar sensor_type/STI se vier no payload
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

      # 2) Timestamp seguro
      read_time =
        begin
          ts = @payload[:timestamp]
          ts.present? ? Time.at(ts.to_f) : Time.current
        rescue
          Time.current
        end

      # 3) Criar leitura (campos existentes na tua schema)
      reading_attrs = {
        temperature:     @payload[:temperature],     # °C (solo / ambiente conforme firmware)
        moisture:        @payload[:moisture],        # % solo
        battery:         @payload[:battery],         # % (vem de battery_pct se existir)
        signal:          @payload[:signal],          # RSSI dBm (wifi_rssi)
        light_intensity: @payload[:light_intensity], # lux (BH1750)
        air_humidity:    @payload[:air_humidity],    # % DHT
        air_temperature: @payload[:air_temperature], # °C DHT (se enviado)
        soil_ph:         @payload[:soil_ph],
        soil_ec:         @payload[:soil_ec],
        soil_nitrogen:   @payload[:soil_nitrogen],
        soil_potassium:  @payload[:soil_potassium],
        soil_phosphorus: @payload[:soil_phosphorus],
        wind_speed:      @payload[:wind_speed],
        wind_direction:  @payload[:wind_direction],
        uptime:          @payload[:uptime],
        error_count:     @payload[:error_count],
        read_at:         read_time
        # raw:           @raw_payload # <- só ativa depois de adicionarmos a coluna jsonb
      }.compact

      @sensor.sensor_readings.create!(reading_attrs)

      # 4) Atualizar “estado” do sensor (cartões/overviews)
      @sensor.update(
        temperature:     @payload[:temperature],
        moisture:        @payload[:moisture],
        battery:         @payload[:battery],
        signal:          @payload[:signal],
        light_intensity: @payload[:light_intensity],
        air_humidity:    @payload[:air_humidity],
        last_reading:    Time.current,
        status:          "Active"
      )

      render json: { status: "created" }, status: :created
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("❌ SensorReading inválido: #{e.record.errors.full_messages.join(', ')}")
      render json: { error: "invalid_reading", details: e.record.errors.full_messages }, status: :unprocessable_entity
    end

    private

    # Desaninha params[:data], aceita chaves “estilo IoT” e mapeia para o nosso modelo.
    # Ex.: hum_air -> air_humidity, lux -> light_intensity, battery_pct -> battery, wifi_rssi -> signal
    def normalize_payload!
      # payload bruto (para futura persistência em raw se quiseres)
      raw = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
      @raw_payload = raw.deep_dup

      # 1) desaninhado
      base = raw["data"].is_a?(Hash) ? raw["data"] : raw
      base = base.deep_symbolize_keys

      # 2) mapeamento principal
      temperature      = base[:temperature] || base[:temp] || base[:temp_c]
      moisture         = base[:moisture]    || base[:soil_pct]
      air_humidity     = base[:air_humidity]|| base[:hum_air]
      air_temperature  = base[:air_temperature] || base[:temp_air] || base[:t_air]
      light_intensity  = base[:light_intensity] || base[:lux]

      # Bateria: preferir percentagem (battery_pct). Se tiver só mV, dá para expor em status, mas não gravamos nos readings
      battery_pct      = base[:battery_pct] || base[:battery] # alguns firmwares já enviam "battery" como %
      battery_mv       = base[:battery_mv]  # útil para logs/diagnóstico
      signal_dbm       = base[:wifi_rssi] || base[:signal]

      mapped = {
        temperature:      to_f_or_nil(temperature),
        moisture:         to_f_or_nil(moisture),
        air_humidity:     to_f_or_nil(air_humidity),
        air_temperature:  to_f_or_nil(air_temperature),
        light_intensity:  to_f_or_nil(light_intensity),
        soil_ph:          to_f_or_nil(base[:soil_ph]),
        soil_ec:          to_f_or_nil(base[:soil_ec]),
        soil_nitrogen:    to_i_or_nil(base[:soil_nitrogen]),
        soil_potassium:   to_i_or_nil(base[:soil_potassium]),
        soil_phosphorus:  to_i_or_nil(base[:soil_phosphorus]),
        battery:          to_i_or_nil(battery_pct),
        signal:           to_i_or_nil(signal_dbm),
        wind_speed:       to_f_or_nil(base[:wind_speed]),
        wind_direction:   to_i_or_nil(base[:wind_direction]),
        uptime:           to_i_or_nil(base[:uptime]),
        error_count:      to_i_or_nil(base[:error_count]),
        sensor_type:      base[:sensor_type],
        timestamp:        base[:timestamp]
      }.compact

      # Guardar ids auxiliares
      @device_id = raw["device_id"] || base[:device_id]
      @sensor_id = params[:sensor_id] || params[:id]

      # Se quiseres usar battery_mv e soil_raw em algum lugar futuro, estão no @raw_payload
      @payload = mapped
    end

    def set_sensor!
      @sensor =
        if @sensor_id.present?
          Sensor.find(@sensor_id)
        elsif @device_id.present?
          Sensor.find_by!(device_id: @device_id)
        else
          raise ActiveRecord::RecordNotFound, "Sem sensor_id nem device_id"
        end
    end

    # Helpers de parsing “tolerantes”
    def to_f_or_nil(v)
      return nil if v.nil? || v == "" || v == "null"
      Float(v) rescue nil
    end

    def to_i_or_nil(v)
      return nil if v.nil? || v == "" || v == "null"
      Integer(v) rescue to_f_or_nil(v)&.round
    end
  end
end
