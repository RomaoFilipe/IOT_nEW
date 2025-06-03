# app/models/sensor_reading.rb
class SensorReading < ApplicationRecord
  belongs_to :sensor

  validates :read_at, presence: true

  after_create :broadcast_update

  private

  def broadcast_update
    SensorReadingsChannel.broadcast_to(
      sensor,
      {
        moisture: moisture,
        temperature: temperature,
        battery: battery,
        signal: signal,
        light_intensity: light_intensity,
        wind_speed: wind_speed,
        wind_direction: wind_direction,
        air_temperature: air_temperature,
        air_humidity: air_humidity,
        soil_ph: soil_ph,
        soil_ec: soil_ec,
        soil_nitrogen: soil_nitrogen,
        soil_potassium: soil_potassium,
        soil_phosphorus: soil_phosphorus,
        uptime: uptime,
        error_count: error_count
      }
    )
  end
end
