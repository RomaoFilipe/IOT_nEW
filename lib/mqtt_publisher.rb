# == lib/mqtt_publisher.rb ==
require 'mqtt'

class MqttPublisher
  def self.publish(topic, payload)
    MQTT::Client.connect(host: ENV["MQTT_BROKER"], port: ENV["MQTT_PORT"].to_i) do |client|
      client.publish(topic, payload)
    end
  rescue => e
    Rails.logger.error "Erro MQTT: #{e.message}"
  end
end