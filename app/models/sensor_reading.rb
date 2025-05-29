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
        battery: battery
      }
    )
  end
  
end
