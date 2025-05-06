module Api
  class SensorsController < Api::BaseController
    before_action :authenticate_api_token!, except: [:identify, :simulate]
    before_action :authenticate_api!, except: [:identify, :simulate]
    before_action :set_sensor, only: [:simulate]

    def identify
      device_id = params[:device_id]

      if device_id.blank?
        render json: { error: "Device ID em branco." }, status: :unprocessable_entity
        return
      end

      sensor = Sensor.find_or_initialize_by(device_id: device_id)

      if sensor.new_record?
        sensor.name = "Sensor #{device_id[-4..] || 'Novo'}"
        sensor.sensor_type = "temperature"
        sensor.status = "Active"
        sensor.battery = rand(60..100)
        sensor.signal = rand(60..100)
        sensor.last_reading = Time.current
        sensor.save!
      end

      render json: {
        id: sensor.id,
        name: sensor.name,
        sensor_type: sensor.sensor_type
      }
    end

    def readings
      @sensor = Sensor.find_by(id: params[:id])

      if @sensor.nil?
        redirect_to sensors_path, alert: "Sensor não encontrado."
        return
      end

      @readings = @sensor.sensor_readings.order(created_at: :desc).limit(100)
    end

    def simulate
      @sensor.update(
        last_value: "#{rand(10..90)}%",
        battery: rand(30..100),
        signal: rand(20..100),
        last_reading: Time.current
      )

      render json: { status: "simulated", updated_at: @sensor.last_reading }
    end

    private

    def authenticate_api_token!
      token = request.headers["Authorization"]&.split("Bearer ")&.last

      if token.blank? || ENV["SENSOR_API_TOKEN"].blank?
        render json: { error: "Token em falta" }, status: :unauthorized
        return
      end

      unless ActiveSupport::SecurityUtils.secure_compare(token, ENV["SENSOR_API_TOKEN"])
        render json: { error: "Token inválido" }, status: :unauthorized
      end
    end

    def set_sensor
      @sensor = Sensor.find(params[:id])
    end
  end
end
