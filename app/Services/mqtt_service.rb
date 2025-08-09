# app/services/mqtt_service.rb
require "mqtt"

class MqttService
  def self.publish_command(device_id, payload)
    host = ENV.fetch("MQTT_HOST", "127.0.0.1")
    port = ENV.fetch("MQTT_PORT", "1883").to_i
    user = ENV["MQTT_USERNAME"]
    pass = ENV["MQTT_PASSWORD"]

    MQTT::Client.connect(host: host, port: port, username: user, password: pass) do |client|
      topic = "sensors/irrigation/#{device_id}/command"
      client.publish(topic, payload.to_json)
      Rails.logger.info "📡 MQTT publicado em #{topic}: #{payload.to_json}"
    end
  rescue => e
    Rails.logger.error "❌ Erro ao publicar MQTT: #{e.class}: #{e.message}"
  end
end
