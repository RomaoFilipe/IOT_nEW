# app/controllers/api/sensor_readings_controller.rb
module Api
  class SensorReadingsController < BaseController
    before_action :authenticate_api!

    # Aceita:
    #  - Formato A (legacy): sensor_id + campos soltos (temperature, moisture, ...)
    #  - Formato B (HiGrow): device_id + data{soil_raw, soil_pct, temp_c, hum_air, lux}
    def create
      Rails.logger.info "🛰️ Recebida leitura: #{params.to_unsafe_h.inspect}"

      sensor = resolve_sensor!

      # 1) Opcional: alinhar tipo do sensor (mantido do teu código)
      normalize_type!(sensor) if params[:sensor_type].present?

      # 2) Timestamp
      measured_at = extract_timestamp(params)

      # 3) Extrair payload normalizado (suporta os dois formatos)
      payload = extract_payload(params)

      # 4) Criar leitura
      reading = sensor.sensor_readings.create!(
        # legacy
        temperature:      payload[:temperature],
        moisture:         payload[:moisture],
        battery:          payload[:battery],
        signal:           payload[:signal],
        light_intensity:  payload[:light_intensity],
        wind_speed:       payload[:wind_speed],
        wind_direction:   payload[:wind_direction],
        air_temperature:  payload[:air_temperature],
        air_humidity:     payload[:air_humidity],
        soil_ph:          payload[:soil_ph],
        soil_ec:          payload[:soil_ec],
        soil_nitrogen:    payload[:soil_nitrogen],
        soil_potassium:   payload[:soil_potassium],
        soil_phosphorus:  payload[:soil_phosphorus],
        uptime:           payload[:uptime],
        error_count:      payload[:error_count],
        read_at:          payload[:read_at] || measured_at,

        # HiGrow
        soil_raw:         payload[:soil_raw],
        soil_pct:         payload[:soil_pct],
        temp_c:           payload[:temp_c],
        hum_air:          payload[:hum_air],
        lux:              payload[:lux],

        # comuns
        measured_at:      measured_at,
        raw:              payload[:raw]
      )

      # 5) Atualizar estado do sensor
      sensor.update(
        battery:      payload[:battery],
        signal:       payload[:signal],
        temperature:  payload[:temperature] || payload[:temp_c],
        moisture:     payload[:moisture]    || payload[:soil_pct],
        last_reading: Time.current,
        status:       "Active"
      )

      render json: { status: "created", id: reading.id }, status: :created
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("❌ Erro a criar leitura: #{e.record.errors.full_messages.join(', ')}")
      render json: { error: e.record.errors.full_messages }, status: :unprocessable_entity
    rescue => e
      Rails.logger.error("❌ Erro inesperado: #{e.message}")
      render json: { error: e.message }, status: :bad_request
    end

    private

    # ---------- Resolvedor de sensor (suporta sensor_id OU device_id) ----------
    def resolve_sensor!
      if params[:sensor_id].present? || params[:id].present?
        Sensor.find(params[:sensor_id] || params[:id])
      else
        device_id = params[:device_id] || params.dig(:data, :device_id)
        raise ArgumentError, "device_id em falta" if device_id.blank?

        sensor = Sensor.find_or_create_by!(device_id: device_id)
        # permite associar já a um field, se vier
        if params[:field_id].present? && sensor.field_id != params[:field_id].to_i
          sensor.update(field_id: params[:field_id])
        end
        sensor
      end
    end

    # ------------------------- Normalização de tipo/STI ------------------------
    def normalize_type!(sensor)
      wanted = params[:sensor_type].to_s.downcase

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

      if sensor.sensor_type != normalized || sensor.type != expected_type
        sensor.update(sensor_type: normalized, type: expected_type)
      end
    end

    # ----------------------- Timestamp a partir dos params ----------------------
    def extract_timestamp(p)
      # aceita: timestamp (epoch seg/ms), measured_at (ISO), read_at (ISO)
      if p[:timestamp].present?
        t = p[:timestamp].to_f
        t = t / 1000.0 if t > 2_000_000_000 # milisegundos
        Time.at(t)
      elsif p[:measured_at].present?
        Time.parse(p[:measured_at].to_s) rescue Time.current
      elsif p[:read_at].present?
        Time.parse(p[:read_at].to_s) rescue Time.current
      else
        Time.current
      end
    end

    # ----------------------- Extrair e unificar o payload -----------------------
    def extract_payload(p)
      data = p[:data].is_a?(ActionController::Parameters) ? p[:data].to_unsafe_h : (p[:data] || {})
      raw  = p.to_unsafe_h

      {
        # legacy
        temperature:      p[:temperature],
        moisture:         p[:moisture],
        battery:          p[:battery],
        signal:           p[:signal],
        light_intensity:  p[:light_intensity],
        wind_speed:       p[:wind_speed],
        wind_direction:   p[:wind_direction],
        air_temperature:  p[:air_temperature],
        air_humidity:     p[:air_humidity],
        soil_ph:          p[:soil_ph],
        soil_ec:          p[:soil_ec],
        soil_nitrogen:    p[:soil_nitrogen],
        soil_potassium:   p[:soil_potassium],
        soil_phosphorus:  p[:soil_phosphorus],
        uptime:           p[:uptime],
        error_count:      p[:error_count],
        read_at:          p[:read_at],

        # HiGrow (dentro de data{})
        soil_raw:         data["soil_raw"] || p[:soil_raw],
        soil_pct:         data["soil_pct"] || p[:soil_pct],
        temp_c:           data["temp_c"]   || p[:temp_c],
        hum_air:          data["hum_air"]  || p[:hum_air],
        lux:              data["lux"]      || p[:lux],

        raw:              raw
      }
    end
  end
end
