class SensorsController < ApplicationController
  require "mqtt"

  before_action :set_field, only: [:create]
  # garantimos que @sensor está definido em todos os membros
  before_action :set_sensor, except: [:lookup, :create]

  # ---------- CRUD ----------
  def create
    @sensor = @field.sensors.build(sensor_params.merge(
      status: "Active",
      battery: rand(60..100),
      signal: rand(60..100),
      last_reading: Time.current
    ))
    if @sensor.save
      respond_to do |f|
        f.turbo_stream
        f.html { redirect_to fields_path, notice: "Sensor criado com sucesso." }
      end
    else
      respond_to do |f|
        f.html { redirect_to fields_path, alert: "Erro ao criar sensor." }
      end
    end
  end

  def lookup
    device_id = params[:device_id]
    return render json: { error: "Device ID em branco." }, status: :unprocessable_entity if device_id.blank?

    sensor = Sensor.find_or_initialize_by(device_id: device_id)
    sensor.sensor_type = params[:sensor_type] if params[:sensor_type].present?
    sensor.name ||= "Sensor #{device_id[-4..]}"
    sensor.status ||= "Active"
    sensor.save!

    render json: { id: sensor.id, name: sensor.name, sensor_type: sensor.sensor_type }
  end

  def simulate
    @sensor.update(
      last_value: "#{rand(10..90)}%",
      battery: rand(30..100),
      signal: rand(20..100),
      last_reading: Time.current
    )
    respond_to do |f|
      f.turbo_stream
      f.html { redirect_to fields_path, notice: "Sensor atualizado." }
    end
  end

  def readings
    @readings = @sensor.sensor_readings.order(Arel.sql("#{canonical_ts_sql} DESC")).limit(100)
  end

  def destroy
    @sensor.destroy
    respond_to do |f|
      f.turbo_stream
      f.html { redirect_to fields_path, notice: "Sensor apagado." }
    end
  end

  # ---------- TEMPO REAL ----------
  # GET /sensors/:id/status_info(.json)
  def status_info
    ts = last_ts_for(@sensor)

    soil = last_numeric(@sensor, "soil_pct", "moisture")
    tmp  = last_numeric(@sensor, "temp_c",   "air_temperature")
    hum  = last_numeric(@sensor, "hum_air",  "air_humidity")
    lux  = last_numeric(@sensor, "lux",      "light_intensity")

    payload = {
      sensor_id: @sensor.id,
      updated_at: ts,
      stale: ts.present? ? ts < 10.minutes.ago : true,

      # chaves novas (atuais)
      soil_pct: soil,
      temp_c:   tmp,
      hum_air:  hum,
      lux:      lux,

      # aliases antigos para retrocompatibilidade
      moisture:        soil,
      air_temperature: tmp,
      air_humidity:    hum,
      light_intensity: lux,

      status: @sensor.status,
      battery: @sensor.try(:battery),
      signal: @sensor.try(:signal),
      irrigation_state: irrigation_state_for(@sensor)
    }

    render json: payload
  end

  # Mantido para quem consome
  def irrigation_status
    if @sensor.status == "irrigando" && @sensor.irrigation_started_at
      elapsed = Time.current - @sensor.irrigation_started_at
      total   = @sensor.irrigation_duration || 120
      remain  = [total - elapsed, 0].max.to_i
      render json: { remaining_time: remain, total_time: total }
    else
      render json: { remaining_time: 0, total_time: 0 }
    end
  end

  def unassign_field
    @sensor.update(field_id: nil)
    redirect_back fallback_location: root_path, notice: "Sensor desassociado com sucesso."
  end

  def irrigation_history
    @irrigation_logs = @sensor.irrigation_logs.order(executed_at: :desc)
  end

  def stop_irrigation
    ActiveRecord::Base.transaction do
      @sensor.update!(status: "parado", last_reading: Time.current, remaining_time: 0)

      @sensor.sensor_readings.create!(status: "parado", read_at: Time.current,
                                      remaining_time: 0, last_duration: @sensor.last_duration)

      @sensor.irrigation_logs.create!(sensor_id: @sensor.id, executed_at: Time.current,
                                      duration: 0, device_id: @sensor.device_id, status: "parado")

      MqttService.publish_command(@sensor.device_id, { action: "stop", origin: "manual" })
      broadcast_irrigation_status(@sensor)
    end

    respond_to do |f|
      f.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          dom_id(@sensor, :irrigation_status_block),
          partial: "sensors/irrigation_status_block",
          locals: { sensor: @sensor }
        )
      end
      f.html { redirect_to dashboard_path, notice: "Irrigação parada manualmente." }
    end
  end

  def start_irrigation
    duration = params[:duration].to_i
    duration = 120 if duration <= 0

    ActiveRecord::Base.transaction do
      @sensor.update!(status: "irrigando", last_reading: Time.current,
                      last_duration: duration, remaining_time: duration)

      @sensor.irrigation_logs.create!(sensor_id: @sensor.id, executed_at: Time.current,
                                      duration: duration, device_id: @sensor.device_id, status: "executado")

      MqttService.publish_command(@sensor.device_id, { action: "start", duration: duration, origin: "manual" })

      ActionCable.server.broadcast("irrigation_#{@sensor.id}", {
        remaining_time: @sensor.remaining_time,
        total_time: @sensor.last_duration
      })
    end

    redirect_to dashboard_path, notice: "Irrigação iniciada manualmente."
  end

  def toggle_status
    @sensor.update(status: @sensor.status == "Active" ? "Inactive" : "Active")
    respond_to do |f|
      f.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          dom_id(@sensor, :row),
          partial: "sensors/row",
          locals: { sensor: @sensor }
        )
      end
      f.html { redirect_back fallback_location: fields_path, notice: "Sensor atualizado." }
    end
  end

  def assign_field
    @sensor.update(field_id: params[:field_id]) if @sensor
    redirect_back fallback_location: fields_path, notice: "Sensor atribuído com sucesso."
  end

  def update_status
    @sensor.update(status: params[:status], last_reading: Time.current)
    html = ApplicationController.renderer.render(partial: "sensors/status", locals: { sensor: @sensor })
    ActionCable.server.broadcast("irrigation_channel", { html: html })
    head :ok
  end

  # ---------- Privados ----------
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

  # SQL para ordenar por timestamp canónico
  def canonical_ts_sql
    "COALESCE(sensor_readings.measured_at, sensor_readings.read_at, sensor_readings.created_at)"
  end

  # timestamp da última leitura (se houver)
  def last_ts_for(sensor)
    sensor.sensor_readings.order(Arel.sql("#{canonical_ts_sql} DESC")).limit(1)
          .pluck(Arel.sql("#{canonical_ts_sql}")).first
  end

  # devolve o último valor não-nulo entre duas colunas (novo/antigo)
  def last_numeric(sensor, col_new, col_old)
    sensor.sensor_readings
          .where("#{col_new} IS NOT NULL OR #{col_old} IS NOT NULL")
          .order(Arel.sql("#{canonical_ts_sql} DESC"))
          .limit(1)
          .pluck(Arel.sql("COALESCE(#{col_new}::numeric, #{col_old}::numeric)"))
          .first&.to_f
  end

  def irrigation_state_for(sensor)
    case sensor.status.to_s.downcase
    when "irrigando" then "A regar"
    when "parado"    then "Parado"
    else sensor.status.presence || "Desconhecido"
    end
  end
end
