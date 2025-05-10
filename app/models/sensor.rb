# IMPLEMENTAÇÃO: IoT Equipment - Simulação de sensores associados a Fields

# 1. MODEL: app/models/sensor.rb
class Sensor < ApplicationRecord
  belongs_to :field, optional: true
  has_many :sensor_readings, dependent: :destroy
  has_many :irrigation_schedules, dependent: :destroy

  SENSOR_TYPES = [
    "Soil Sensor",
    "Weather Station",
    "Irrigation Valve",
    "Soil PH",
    "Light Sensor"
  ]

  ICONS = {
    "Soil Sensor" => "💧",
    "Weather Station" => "☂️",
    "Irrigation Valve" => "🚰",
    "Soil PH" => "🧪",
    "Light Sensor" => "☀️"
  }

  def irrigation_sensor?
    sensor_type == "irrigation"
  end
end
