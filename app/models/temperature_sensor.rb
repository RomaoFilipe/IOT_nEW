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