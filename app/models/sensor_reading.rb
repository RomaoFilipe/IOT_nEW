class SensorReading < ApplicationRecord
  belongs_to :sensor

  # ----- Scopes -----
  scope :for_field, ->(field_id) {
    joins(sensor: :field).where(fields: { id: field_id })
  }

  scope :between_ts, ->(from_time, to_time) {
    where(Arel.sql("#{ts_sql} BETWEEN :from AND :to"), from: from_time, to: to_time)
  }

  # ----- SQL helpers (compatibilidade colunas) -----
  def self.ts_sql
    # timestamp canónico (usa measured_at, senão read_at, senão created_at)
    "COALESCE(sensor_readings.measured_at, sensor_readings.read_at, sensor_readings.created_at)"
  end

  def self.air_temp_sql
    # suporta temp_c (decimal) e air_temperature (float)
    "COALESCE(sensor_readings.temp_c, sensor_readings.air_temperature)"
  end

  def self.air_hum_sql
    # suporta hum_air (decimal) e air_humidity (integer)
    "COALESCE(sensor_readings.hum_air, sensor_readings.air_humidity)"
  end
end
