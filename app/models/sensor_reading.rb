# app/models/sensor_reading.rb
class SensorReading < ApplicationRecord
  belongs_to :sensor
  delegate :field, to: :sensor

  validates :read_at, presence: true

  # Realtime para o bloco de métricas do campo (Turbo Streams)
  after_create_commit :broadcast_metrics_frame

  # Realtime por sensor via ActionCable (já usavas)
  after_create_commit :broadcast_sensor_channel

  private

  def broadcast_metrics_frame
    broadcast_replace_later_to(
      [field, :metrics],
      target: ActionView::RecordIdentifier.dom_id(field, :metrics),
      partial: "fields/metrics",
      locals: { field: field }
    )
  end

  def broadcast_sensor_channel
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
        error_count: error_count,
        read_at: read_at
      }
    )
  end
end
