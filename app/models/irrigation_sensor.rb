# app/models/irrigation_sensor.rb
class IrrigationSensor < Sensor
has_many :irrigation_schedules, foreign_key: :sensor_id, dependent: :destroy
  # ⚠️ Usamos logs com base no device_id para flexibilidade
  def irrigation_logs
    IrrigationLog.where(device_id: device_id)
  end

  def irrigation_sensor?
    true
  end

  # ⏳ Tempo restante baseado em last_reading + última duração
  def remaining_time
    return 0 unless status == "irrigando"
  
    latest_log = irrigation_logs.order(created_at: :desc).first
    return 0 unless latest_log.present?
  
    base_time = last_reading || latest_log.executed_at
    elapsed = Time.current - base_time
    remaining = latest_log.duration - elapsed
    remaining > 0 ? remaining.round : 0
  end
  
  
  

  # ⌛ Última duração vinda do log mais recente
  def last_duration
    irrigation_logs.order(created_at: :desc).limit(1).pluck(:duration).first || 60
  end
end
