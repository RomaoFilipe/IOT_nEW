# app/models/sensor_reading.rb
class SensorReading < ApplicationRecord
  belongs_to :sensor

  validates :read_at, presence: true
end
