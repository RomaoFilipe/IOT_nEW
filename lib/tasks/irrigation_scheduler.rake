# lib/tasks/irrigation_scheduler.rake
namespace :irrigation do
  desc "Verifica agendamentos e envia comandos MQTT"
  task run: :environment do
    now = Time.zone.now
    schedules = IrrigationSchedule.where(day_of_week: now.wday, hour: now.hour, minute: now.min)

    schedules.each do |s|
      topic = "sensors/irrigation/#{s.sensor.device_id}/command"
      payload = { action: "start", duration: s.duration }.to_json
      puts "Publicar para #{topic}: #{payload}"
      MqttPublisher.publish(topic, payload)
    end
  end
end