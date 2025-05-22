# app/models/sensor.rb
class Sensor < ApplicationRecord

  self.inheritance_column = :type  # Para garantir que 'type' é usado para STI

  belongs_to :field, optional: true
  has_many :sensor_readings, dependent: :destroy
  has_many :irrigation_schedules, dependent: :destroy
  has_many :irrigation_logs, dependent: :destroy

  validates :name, presence: true
  validates :device_id, presence: true
  validates :device_id, uniqueness: true, if: -> { new_record? || will_save_change_to_device_id? }
  validates :sensor_type, presence: true
  validates :status, inclusion: { in: %w[Active Inactive parado irrigando] }, allow_nil: true

  def active?
    status == "Active"
  end

  def update_reading(value:, timestamp: Time.current)
    self.last_value = value
    self.last_reading = timestamp
    save!
  end
end

# app/models/temperature_sensor.rb
class TemperatureSensor < Sensor
  # Campos específicos para sensores de temperatura/humidade:
  # - temperature (float)
  # - moisture (float)

  validates :temperature, numericality: { greater_than_or_equal_to: -50, less_than_or_equal_to: 100 }, allow_nil: true
  validates :moisture, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

  def update_measurements(temperature:, moisture:, timestamp: Time.current)
    self.temperature = temperature
    self.moisture = moisture
    self.last_reading = timestamp
    save!
  end

  def status_summary
    {
      temperature: temperature,
      moisture: moisture,
      last_reading: last_reading,
      battery: battery,
      signal: signal,
      active: active?
    }
  end
end

# app/models/irrigation_sensor.rb
class IrrigationSensor < Sensor
  has_many :irrigation_logs, dependent: :destroy
  has_many :irrigation_schedules, dependent: :destroy

  def irrigation_sensor?
    true
  end
end
