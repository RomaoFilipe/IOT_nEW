# frozen_string_literal: true
module Api
  class SensorReadingsController < BaseController
    before_action :authenticate_api!
    before_action :normalize_payload!
    before_action :set_sensor!

    # POST /api/sensors/:id/readings
    # POST /api/sensors/:sensor_id/readings
    # POST /api/sensors/readings  (com { device_id: "...", data: {...} })
    def create
      Rails.logger.info("🛰️ leitura(normalizada)= #{@payload.inspect}")

      # 1) timestamp seguro
      read_time =
        begin
          ts = @payload[:timestamp]
          ts.present? ? Time.at(ts.to_f) : Time.current
        rescue
          Time.current
        end

      # 2) criar registo de leitura
      reading = @sensor.sensor_readings.create!(
        temperature:      @payload[:temperature],      # °C do sensor
        moisture:         @payload[:moisture],         # % solo
        air_humidity:     @payload[:air_humidity],     # % ar
        light_intensity:  @payload[:light_intensity],  # lux
        soil_ph:          @payload[:soil_ph],
        soil_ec:          @payload[:soil_ec],
        soil_nitrogen:    @payload[:soil_nitrogen],
        soil_potassium:   @payload[:soil_potassium],
        soil_phosphorus:  @payload[:soil_phosphorus],
        battery:          @payload[:battery],          # %
        signal:           @payload[:signal],           # dBm
        wind_speed:       @payload[:wind_speed],
        wind_direction:   @payload[:wind_direction],
        uptime:           @payload[:uptime],
        error_count:      @payload[:error_count],
        read_at:          read_time,
        raw:              @raw_payload                 # guarda payload bruto (jsonb)
      )

      # 3) atualizar “estado rápido” no Sensor (apenas colunas que existem)
      sensor_updates = {
        battery:      @payload[:battery],
        signal:       @payload[:signal],
        temperature:  @payload[:temperature],
        moisture:     @payload[:moisture],
        light_intensity: @payload[:light_intensity],
        last_reading: Time.current,
        status:       "Active"
      }.compact

      # evita NoMethodError para colunas que não existam neste teu schema
      sensor_updates.select! { |k, _| @sensor.has_attribute?(k) }
      @sensor.update(sensor_updates) if sensor_updates.any?

      render json: { status: "created", id: reading.id }, status: :created
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn("❌ leitura inválida: #{e.record.errors.full_messages}")
      render json: { error: e.record.errors.full_messages }, status: :unprocessable_entity
    end

    private

    # Desaninha params[:data], aceita variações de nomes (temp_c, hum_air, lux,
    # battery_mv/battery_pct, wifi_rssi, etc.) e converte de forma segura.
    def normalize_payload!
      raw = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
      @raw_payload = raw.deep_dup

      base = raw["data"].is_a?(Hash) ? raw["data"] : raw
      base = base.deep_symbolize_keys

      # fontes alternativas
      t_c      = base[:temperature] || base[:temp] || base[:temp_c]
      moist    = base[:moisture] || base[:soil_pct]
      hum_air  = base[:air_humidity] || base[:hum_air]
      lux      = base[:light_intensity] || base[:lux]
      batt_pct = base[:battery_pct] || base[:battery] # preferimos nível em %
      rssi     = base[:wifi_rssi]   || base[:signal]

      # construir mapa normalizado (com parsers tolerantes)
      @payload = {
        temperature:      to_f_or_nil(t_c),
        moisture:         to_f_or_nil(moist),
        air_humidity:     to_f_or_nil(hum_air),
        light_intensity:  to_f_or_nil(lux),
        soil_ph:          to_f_or_nil(base[:soil_ph]),
        soil_ec:          to_f_or_nil(base[:soil_ec]),
        soil_nitrogen:    to_i_or_nil(base[:soil_nitrogen]),
        soil_potassium:   to_i_or_nil(base[:soil_potassium]),
        soil_phosphorus:  to_i_or_nil(base[:soil_phosphorus]),
        battery:          to_i_or_nil(batt_pct),   # %
        signal:           to_i_or_nil(rssi),       # dBm
        wind_speed:       to_f_or_nil(base[:wind_speed]),
        wind_direction:   to_i_or_nil(base[:wind_direction]),
        uptime:           to_i_or_nil(base[:uptime]),
        error_count:      to_i_or_nil(base[:error_count]),
        sensor_type:      base[:sensor_type],
        timestamp:        base[:timestamp]
      }.compact

      @device_id = raw["device_id"] || base[:device_id]
      @sensor_id = params[:sensor_id] || params[:id]
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

      # opcional: alinhar tipo se vier no payload
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
    end

    # ───── helpers “tolerantes” ─────
    def to_f_or_nil(v)
      return nil if v.nil? || v == "" || v == "null"
      Float(v) rescue nil
    end

    def to_i_or_nil(v)
      return nil if v.nil? || v == "" || v == "null"
      Integer(v) rescue(to_f_or_nil(v)&.round)
    end
  end
end
