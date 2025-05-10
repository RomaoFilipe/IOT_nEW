module Api
  class SensorsController < Api::BaseController
    before_action :set_sensor, except: [:identify]
    before_action :authenticate_api_token!, except: [:identify, :simulate]
    before_action :authenticate_api!, except: [:identify, :simulate]
    

    def identify
      device_id = params[:device_id]
      sensor_type = params[:sensor_type] || "temperature"
    
      if device_id.blank?
        render json: { error: "Device ID em branco." }, status: :unprocessable_entity
        return
      end
    
      sensor = Sensor.find_or_initialize_by(device_id: device_id)
    
      if sensor.new_record?
        sensor.name = device_id               # 👈 Aqui usamos o DEVICE_ID como nome
        sensor.sensor_type = sensor_type
        sensor.status = "Active"
        sensor.battery = rand(60..100)
        sensor.signal = rand(60..100)
        sensor.last_reading = Time.current
        sensor.save!
      else
        # Atualiza o tipo se for enviado e diferente
        if sensor.sensor_type != sensor_type
          sensor.update(sensor_type: sensor_type)
        end
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
        last_reading: Time.current,
        status: "Active" # 👈 ativa o sensor
      )
    
      render json: { status: "simulated", updated_at: @sensor.last_reading }
    end

    def toggle_status
      if @sensor.status == "Active"
        @sensor.update(status: "Inactive")
      elsif @sensor.last_reading.present? && @sensor.last_reading > 5.minutes.ago
        @sensor.update(status: "Active")
      else
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.append("flash", partial: "shared/flash", locals: { message: "Sensor sem sinal recente.", type: :alert }) }
          format.json { render json: { error: "Sensor sem sinal recente." }, status: :forbidden }
        end
        return
      end
    
      respond_to do |format|
        format.turbo_stream
        format.json { render json: { status: @sensor.status } }
      end
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
      @sensor = Sensor.find(params[:sensor_id] || params[:id])
    end
  end
end
