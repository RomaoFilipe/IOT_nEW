class IrrigationSensor < Sensor
  has_many :irrigation_schedules, dependent: :destroy
  # ⚠️ Removido este has_many porque estamos a usar device_id manualmente:
  # has_many :irrigation_logs, dependent: :destroy

  def irrigation_sensor?
    true
  end

  def remaining_time
    return 0 unless status == "irrigando" && last_reading.present? && last_duration.present?
    elapsed = Time.current - last_reading
    remaining = last_duration - elapsed
    remaining > 0 ? remaining.round : 0
  end

  def last_duration
    irrigation_logs.order(created_at: :desc).limit(1).pluck(:duration).first || 60
  end

  

  def irrigation_logs
    IrrigationLog.where(device_id: device_id)
  end
end
