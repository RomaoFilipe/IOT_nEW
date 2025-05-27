require_relative "../mqtt_publisher"

namespace :irrigation do
  desc "Executa agendamentos se for a hora correta e ainda não foram executados hoje"
  task :run do
    now = Time.now
    puts "⏰ Verificando agendamentos para #{now.strftime('%H:%M')}..."

    schedules = IrrigationSchedule.where(
      hour: now.hour,
      minute: now.min,
      day_of_week: now.wday
    ).select do |s|
      s.executed_at.nil? || s.executed_at.to_date != now.to_date
    end

    if schedules.empty?
      puts "📭 Nenhum agendamento para este minuto."
    end

    schedules.each do |schedule|
      sensor = schedule.sensor
      if sensor
        puts "💧 Enviando irrigação para #{sensor.device_id} (#{schedule.duration}s)"
        MqttPublisher.send_command(sensor.device_id, schedule.duration || 60)
        schedule.update(executed_at: now)
      else
        puts "⚠️ Sensor não encontrado para agendamento #{schedule.id}"
      end
    end
  end
end
