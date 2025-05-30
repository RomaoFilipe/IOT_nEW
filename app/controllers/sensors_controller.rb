class SensorsController < ApplicationController
  require "mqtt"
  before_action :set_field, only: [:create]
  before_action :set_sensor, except: [:lookup, :create, :start_irrigation]

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
    return render json: { error: "Device ID em branco." }, status: :unprocessable_entity if device_id.blank?

    sensor = Sensor.find_or_initialize_by(device_id: device_id)
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
    render json: {
      status: @sensor.status,
      remaining_time: @sensor.try(:remaining_time) || 0
    }
  end

  def irrigation_status
    sensor = Sensor.find(params[:id])

    if sensor.status == "irrigando" && sensor.irrigation_started_at
      elapsed = Time.current - sensor.irrigation_started_at
      total_time = sensor.irrigation_duration || 120
      remaining_time = [total_time - elapsed, 0].max.to_i

      render json: { remaining_time: remaining_time, total_time: total_time }
    else
      render json: { remaining_time: 0, total_time: 0 }
    end
  end

  def irrigation_history
    @irrigation_logs = @sensor.irrigation_logs.order(executed_at: :desc)
    Rails.logger.debug "Irrigation logs count: #{@irrigation_logs.count}"
    Rails.logger.debug @irrigation_logs.inspect
  end

  def stop_irrigation
    ActiveRecord::Base.transaction do
      @sensor.update!(
        status: "parado",
        last_reading: Time.current,
        remaining_time: 0
      )

      @sensor.sensor_readings.create!(
        status: "parado",
        read_at: Time.current,
        remaining_time: 0,
        last_duration: @sensor.last_duration
      )

      @sensor.irrigation_logs.create!(
        sensor_id: @sensor.id,
        executed_at: Time.current,
        duration: 0,
        device_id: @sensor.device_id,
        status: "parado"
      )

      mqtt_payload = { action: "stop", origin: "manual" }
      MqttService.publish_command(@sensor.device_id, mqtt_payload)

      broadcast_irrigation_status(@sensor)
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          dom_id(@sensor, :irrigation_status_block),
          partial: "sensors/irrigation_status_block",
          locals: { sensor: @sensor }
        )
      end
      format.html { redirect_to dashboard_path, notice: "Irrigação parada manualmente." }
    end
  end

  def start_irrigation
    duration = params[:duration].to_i
    duration = 120 if duration <= 0

    unless @sensor
      redirect_back fallback_location: dashboard_path, alert: "Sensor não encontrado."
      return
    end

    ActiveRecord::Base.transaction do
      @sensor.update!(
        status: "irrigando",
        last_reading: Time.current,
        last_duration: duration,
        remaining_time: duration
      )

      @sensor.irrigation_logs.create!(
        sensor_id: @sensor.id,
        executed_at: Time.current,
        duration: duration,
        device_id: @sensor.device_id,
        status: "executado"
      )

      mqtt_payload = {
        action: "start",
        duration: duration,
        origin: "manual"
      }

      MqttService.publish_command(@sensor.device_id, mqtt_payload)

      ActionCable.server.broadcast("irrigation_#{@sensor.id}", {
        remaining_time: @sensor.remaining_time,
        total_time: @sensor.last_duration
      })
    end

    redirect_to dashboard_path, notice: "Irrigação iniciada manualmente."
  end

  def toggle_status
    @sensor.update(status: @sensor.status == "Active" ? "Inactive" : "Active")
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          dom_id(@sensor, :row),
          partial: "sensors/row",
          locals: { sensor: @sensor }
        )
      end
      format.html { redirect_back fallback_location: fields_path, notice: "Sensor atualizado." }
    end
  end

  def assign_field
    if @sensor
      @sensor.update(field_id: params[:field_id])
      redirect_back fallback_location: fields_path, notice: "Sensor atribuído com sucesso."
    else
      redirect_back fallback_location: fields_path, alert: "Sensor não encontrado."
    end
  end

  def update_status
    @sensor = Sensor.find(params[:id])
    @sensor.update(status: params[:status], last_reading: Time.current)

    html = ApplicationController.renderer.render(
      partial: "sensors/status",
      locals: { sensor: @sensor }
    )

    ActionCable.server.broadcast("irrigation_channel", { html: html })
    head :ok
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

  def broadcast_irrigation_status(sensor)
    ActionCable.server.broadcast("irrigation_#{sensor.id}", {
      remaining_time: sensor.remaining_time,
      total_time: sensor.last_duration
    })
  end
end
