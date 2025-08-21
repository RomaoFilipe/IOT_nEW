# frozen_string_literal: true

module Api
  class SensorReadingsController < BaseController
    before_action :authenticate_api!
    before_action :normalize_payload!
    before_action :set_sensor!

    # POST /api/sensors/:id/readings
    # ou POST /api/sensors/readings (com device_id no corpo via routers que apontem aqui)
    def create
      Rails.logger.info "🛰️ Recebida leitura normalizada: #{@payload.inspect}"

      # 1) Opcional: alinhar sensor_type / STI se o firmware disser o tipo
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

      # 2) timestamp seguro
      read_time =
        begin
          ts = @payload[:timestamp]
          ts.present? ? Time.at(ts.to_f) : Time.current
        rescue
          Time.current
        end

      # 3) Criar leitura (apenas colunas existentes na tabela)
      reading_attrs = {
        temperature:      @payload[:temperature],
        moisture:         @payload[:moisture],
        battery:          @payload[:battery],
        signal:           @payload[:signal],
        light_intensity:  @payload[:light_intensity],
        wind_speed:       @payload[:wind_speed],
        wind_direction:   @payload[:wind_direction],
        air_temperature:  @payload[:air_temperature],
        air_humidity:     @payload[:air_humidity],
        soil_ph:          @payload[:soil_ph],
        soil_ec:          @payload[:soil_ec],
        soil_nitrogen:    @payload[:soil_nitrogen],
        soil_potassium:   @payload[:soil_potassium],
        soil_phosphorus:  @payload[:soil_phosphorus],
        uptime:           @payload[:uptime],
        error_count:      @payload[:error_count],
        read_at:          read_time,
        raw:              @raw_payload # guarda payload bruto (se tens a coluna :raw -> jsonb)
      }.compact

      @sensor.sensor_readings.create!(reading_attrs)

      # 4) Atualizar “estado” do Sensor (só colunas que existem no modelo Sensor)
      sensor_updates = {
        battery:      @payload[:battery],
        signal:       @payload[:signal],
        temperature:  @payload[:temperature],
        moisture:     @payload[:moisture],
        last_reading: Time.current,
        status:       "Active"
      }.compact

      # Não assumimos que existem colunas como :air_humidity, :light_intensity no modelo Sensor
      # (a tua stack mostrou NoMethodError ao tentar ler s.air_humidity).
      permitted_cols = Sensor.column_names.map(&:to_sym)
      sensor_updates.slice!(*permitted_cols)

      @sensor.update(sensor_updates) if sensor_updates.any?

      render json: { status: "created" }, status: :created
    end

    private

    # Converte o payload (aninhado ou flat) para o formato interno
    def normalize_payload!
      raw = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
      @raw_payload = raw.deep_dup # para guardar em sensor_readings.raw

      # desaninha se vier em { data: { ... } }
      base = raw["data"].is_a?(Hash) ? raw["data"] : raw
      base = base.deep_symbolize_keys

      # fontes alternativas
      temperature      = pick_float(base, :temperature, :temp, :temp_c)
      moisture         = pick_float(base, :moisture, :soil_pct)
      air_humidity     = pick_float(base, :air_humidity, :hum_air)
      air_temperature  = pick_float(base, :air_temperature, :t_air, :temp_air)
      light_intensity  = pick_float(base, :light_intensity, :lux)
      battery_pct      = pick_int(base,   :battery, :battery_pct)   # percent
      wifi_rssi        = pick_int(base,   :signal,  :wifi_rssi)     # dBm (negativo)
      soil_ph          = pick_float(base, :soil_ph)
      soil_ec          = pick_float(base, :soil_ec)
      soil_nitrogen    = pick_int(base,   :soil_nitrogen)
      soil_potassium   = pick_int(base,   :soil_potassium)
      soil_phosphorus  = pick_int(base,   :soil_phosphorus)
      wind_speed       = pick_float(base, :wind_speed)
      wind_direction   = pick_int(base,   :wind_direction)
      uptime           = pick_int(base,   :uptime)
      error_count      = pick_int(base,   :error_count)

      @payload = {
        temperature:      temperature,
        moisture:         moisture,
        air_humidity:     air_humidity,
        air_temperature:  air_temperature,
        light_intensity:  light_intensity,
        battery:          battery_pct,
        signal:           wifi_rssi,
        soil_ph:          soil_ph,
        soil_ec:          soil_ec,
        soil_nitrogen:    soil_nitrogen,
        soil_potassium:   soil_potassium,
        soil_phosphorus:  soil_phosphorus,
        wind_speed:       wind_speed,
        wind_direction:   wind_direction,
        uptime:           uptime,
        error_count:      error_count,
        sensor_type:      base[:sensor_type],
        timestamp:        base[:timestamp]
      }.compact

      # ids auxiliares para lookup de sensor
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
    end

    # ---------- helpers de parsing “tolerantes” ----------
    def pick_float(hash, *keys)
      v = keys.filter_map { |k| hash[k] }.first
      to_f_or_nil(v)
    end

    def pick_int(hash, *keys)
      v = keys.filter_map { |k| hash[k] }.first
      to_i_or_nil(v)
    end

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
