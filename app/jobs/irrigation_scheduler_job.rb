class IrrigationSchedulerJob < ApplicationJob
  queue_as :default

  def perform
    now = Time.zone.now
    current_day = now.wday
    current_hour = now.hour
    current_minute = now.min

    schedules = IrrigationSchedule.includes(:sensor).where(
      day_of_week: current_day,
      hour: current_hour,
      minute: current_minute
    )

    schedules.each do |schedule|
      sensor = schedule.sensor
      next unless sensor&.device_id.present?

      topic = "sensors/irrigation/#{sensor.device_id}/command"
      payload = {
        action: "start",
        duration: schedule.duration
      }

      begin
        client = MQTT::Client.connect("tcp://192.168.1.77:1883") # IP do teu broker
        client.publish(topic, payload.to_json)
        client.disconnect

        Rails.logger.info "✅ Comando enviado para #{sensor.device_id}: #{payload}"
      rescue => e
        Rails.logger.error "❌ Erro ao enviar comando MQTT para #{sensor.device_id}: #{e.message}"
      end
    end
  end
end
