# app/lib/mqtt_publisher.rb
require 'mqtt'

class MqttPublisher
  def self.publish(topic, payload)
    host = ENV["MQTT_BROKER"] || "localhost"
    port = (ENV["MQTT_PORT"] || "1883").to_i

    MQTT::Client.connect(host: host, port: port) do |client|
      client.publish(topic, payload)
      puts "📤 MQTT publicado em #{topic}: #{payload}"
    end
  rescue => e
    puts "❌ Erro MQTT: #{e.message}"
  end
end
