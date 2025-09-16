class IrrigationFinishJob < ApplicationJob
  queue_as :default

  def perform(sensor_id)
    sensor = Sensor.find_by(id: sensor_id)
    return unless sensor && sensor.status.to_s.downcase == "irrigando"

    total = sensor.last_duration.to_i
    started_at = sensor.irrigation_started_at
    return unless started_at && total.positive?
    return if Time.current < (started_at + total.seconds) # ainda não terminou (reagendado?)

    # marca como parado (idempotente)
    Sensor.transaction do
      sensor.update!(status: "parado", remaining_time: 0)
      sensor.sensor_readings.create!(status: "parado", read_at: Time.current, remaining_time: 0, last_duration: sensor.last_duration)
      sensor.irrigation_logs.create!(sensor_id: sensor.id, executed_at: Time.current, duration: 0, device_id: sensor.device_id, status: "parado")
    end

    # broadcast UI por-sensor (o que já tens)
    ActionCable.server.broadcast("irrigation_#{sensor.id}", { remaining_time: 0, total_time: sensor.last_duration })

    # aviso global
    ActionCable.server.broadcast("notifications", {
      kind: "irrigation_finished",
      sensor_id: sensor.id,
      field_id:  sensor.field_id,
      field:     sensor.field&.name,
      message:   I18n.t("notifications.irrigation_finished",
                        default: "Irrigação terminada no campo %{field}",
                        field: sensor.field&.name || "#"+sensor.field_id.to_s),
      ended_at:  Time.current.iso8601
    })
  end
end
