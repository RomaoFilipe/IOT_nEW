class IrrigationSensor < Sensor
  has_many :irrigation_schedules, dependent: :destroy
  has_many :irrigation_logs, dependent: :destroy
  def irrigation_sensor?
    true
  end
end