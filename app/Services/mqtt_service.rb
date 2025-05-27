# app/services/mqtt_service.rb
require 'mqtt'

class MqttService
  def self.publish_command(device_id, payload)
    MQTT::Client.connect(host: '192.168.1.77', port: 1883) do |client|
      topic = "sensors/irrigation/#{device_id}/command"
      client.publish(topic, payload.to_json)
      Rails.logger.info "📡 MQTT enviado para #{topic}: #{payload.to_json}"
    end
  rescue => e
    Rails.logger.error "❌ Erro ao publicar MQTT: #{e.message}"
  end
end
