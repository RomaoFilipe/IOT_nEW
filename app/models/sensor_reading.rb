# app/models/sensor_reading.rb
class SensorReading < ApplicationRecord
  belongs_to :sensor

  # =========================
  # SQL helpers (nomes novos/antigos)
  # =========================
  def self.ts_sql
    "COALESCE(sensor_readings.measured_at, sensor_readings.read_at, sensor_readings.created_at)"
  end

  def self.soil_sql
    "COALESCE(sensor_readings.soil_pct, sensor_readings.moisture)"
  end

  def self.air_temp_sql
    "COALESCE(sensor_readings.temp_c, sensor_readings.air_temperature)"
  end

  def self.air_hum_sql
    "COALESCE(sensor_readings.hum_air, sensor_readings.air_humidity)"
  end

  def self.lux_sql
    "COALESCE(sensor_readings.lux, sensor_readings.light_intensity)"
  end

  # =========================
  # Scopes úteis
  # =========================
  scope :between_ts, ->(from_time, to_time) {
    where(Arel.sql("#{ts_sql} BETWEEN :from AND :to"), from: from_time, to: to_time)
  }

  # Usa joins explícitos para evitar erros de associação em algumas versões/adapters
  scope :for_field, ->(field_id) {
    joins("INNER JOIN sensors ON sensors.id = sensor_readings.sensor_id")
      .where(sensors: { field_id: field_id })
  }

  scope :for_account, ->(account_id) {
    joins("INNER JOIN sensors ON sensors.id = sensor_readings.sensor_id")
      .joins("INNER JOIN fields  ON fields.id  = sensors.field_id")
      .where(fields: { account_id: account_id })
  }
end
