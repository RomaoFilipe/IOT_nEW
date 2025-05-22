# app/models/sensor_reading.rb
class SensorReading < ApplicationRecord
  belongs_to :sensor
  t.string :status         # "irrigando" ou "parado"
  t.integer :remaining_time
  t.integer :last_duration
  
  validates :read_at, presence: true
end
