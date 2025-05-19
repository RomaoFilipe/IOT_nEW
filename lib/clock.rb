require 'clockwork'
require_relative '../config/environment'

# ⚠️ Define o método antes do módulo Clockwork usar
def schedule_matches_now?(schedule, time)
  schedule.day_of_week.to_i == time.wday &&
    schedule.hour.to_i == time.hour &&
    schedule.minute.to_i == time.min
end

module Clockwork
  every(1.minute, 'Verificar agendamentos de irrigação') do
    now = Time.zone.now

    IrrigationSchedule.includes(:sensor).find_each do |schedule|
      next unless schedule_matches_now?(schedule, now)

      sensor = schedule.sensor
      next unless sensor&.device_id.present?

      MqttService.publish_command(sensor.device_id, {
        action: 'start',
        duration: schedule.duration
      })
    end
  end
end
