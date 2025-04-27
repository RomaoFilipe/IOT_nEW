# IMPLEMENTAÇÃO: IoT Equipment - Simulação de sensores associados a Fields

# 1. MODEL: app/models/sensor.rb
class Sensor < ApplicationRecord
  belongs_to :field

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
end
