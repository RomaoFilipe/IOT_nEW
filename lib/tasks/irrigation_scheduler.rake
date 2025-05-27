# Rakefile
require_relative './app/lib/mqtt_publisher'  # 👈 fixado aqui
require 'active_support/all'
require 'dotenv/load'
require 'pg'
require 'active_record'

ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])

class IrrigationSchedule < ActiveRecord::Base
  belongs_to :sensor
end

class Sensor < ActiveRecord::Base
end

namespace :irrigation do
  desc "Verifica agendamentos e envia comandos MQTT"
  task run do
    now = Time.now

    start_window = now.change(sec: 0)
    end_window = now + 2.minutes

    puts "⏰ [#{now.strftime('%H:%M')}] Verificando agendamentos entre #{start_window.strftime('%H:%M')} e #{end_window.strftime('%H:%M')}..."

    schedules = IrrigationSchedule
      .where(day_of_week: now.wday)
      .where(hour: start_window.hour, minute: start_window.min..end_window.min)
      .where("executed_at IS NULL OR DATE(executed_at) < ?", now.to_date)

    if schedules.empty?
      puts "✅ Nenhum agendamento neste intervalo."
    else
      schedules.each do |s|
        sensor = s.sensor
        next unless sensor&.device_id.present?

        topic = "sensors/irrigation/#{sensor.device_id}/command"
        payload = { action: "start", duration: s.duration }.to_json

        puts "📤 Enviando comando MQTT para #{sensor.device_id} (#{s.duration}s)"
        MqttPublisher.publish(topic, payload)
        s.update(executed_at: now)
      end
    end
  end
end
