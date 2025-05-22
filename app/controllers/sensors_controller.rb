class SensorsController < ApplicationController
  before_action :set_field, only: [:create]
  before_action :set_sensor

  def create
    @sensor = @field.sensors.build(sensor_params.merge(
      status: "Active",
      battery: rand(60..100),
      signal: rand(60..100),
      last_reading: Time.current
    ))

    if @sensor.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to fields_path, notice: "Sensor criado com sucesso." }
      end
    else
      respond_to do |format|
        format.html { redirect_to fields_path, alert: "Erro ao criar sensor." }
      end
    end
  end

  def lookup
    device_id = params[:device_id]

    if device_id.blank?
      render json: { error: "Device ID em branco." }, status: :unprocessable_entity
      return
    end

    sensor = Sensor.find_or_initialize_by(device_id: device_id)

    # Atualiza tipo e nome se estiverem incluídos no payload
    sensor.sensor_type = params[:sensor_type] if params[:sensor_type].present?
    sensor.name = "Sensor #{device_id[-4..]}" if sensor.name.blank?
    sensor.status ||= "Active"
    sensor.save!
    
    render json: {
      id: sensor.id,
      name: sensor.name,
      sensor_type: sensor.sensor_type
    }
  end

  def simulate
    @sensor.update(
      last_value: "#{rand(10..90)}%",
      battery: rand(30..100),
      signal: rand(20..100),
      last_reading: Time.current
    )

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to fields_path, notice: "Sensor atualizado." }
    end
  end

  def readings
    @sensor = Sensor.find_by(id: params[:id])

    if @sensor.nil?
      redirect_to sensors_path, alert: "Sensor não encontrado."
      return
    end

    @readings = @sensor.sensor_readings.order(read_at: :desc).limit(100)
  end

  def destroy
    @sensor.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to fields_path, notice: "Sensor apagado." }
    end
  end

  def status_info
    sensor = Sensor.find(params[:id])
    render json: {
      status: sensor.status,
      remaining_time: sensor.try(:remaining_time) || 0
    }
  end
  

  def irrigation_history
    @sensor = Sensor.find(params[:id])
    @irrigation_logs = @sensor.irrigation_logs.order(executed_at: :desc)
  
    Rails.logger.debug "Irrigation logs count: #{@irrigation_logs.count}"
    Rails.logger.debug @irrigation_logs.inspect
  end
  
  

  def toggle_status
    @sensor.update(status: @sensor.status == "Active" ? "Inactive" : "Active")

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          dom_id(@sensor, :row), # 👈 IMPORTANTE: usa `:row` para bater com `dom_id(sensor, :row)` no HTML
          partial: "sensors/row",
          locals: { sensor: @sensor }
        )
      end
      format.html { redirect_back fallback_location: fields_path, notice: "Sensor atualizado." }
    end
  end

  def assign_field
    @sensor.update(field_id: params[:field_id])
    redirect_back fallback_location: fields_path, notice: "Sensor atribuído com sucesso."
  end

  private

  def set_field
    @field = Field.find(params[:field_id])
  end

  def set_sensor
    @sensor = Sensor.find(params[:sensor_id] || params[:id])
  end

  def sensor_params
    params.require(:sensor).permit(:name, :sensor_type)
  end
end
