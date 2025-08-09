# frozen_string_literal: true
require "mqtt"

class MqttBridge
  TOPICS = [
    "sensors/data",                 # identidade/telemetria
    "sensors/irrigation/+/status"   # estados do dispositivo
  ].freeze

  def initialize(logger: Rails.logger)
    @logger    = logger
    @host      = ENV.fetch("MQTT_HOST", "127.0.0.1")
    @port      = ENV.fetch("MQTT_PORT", "1883").to_i
    @user      = ENV["MQTT_USERNAME"]
    @pass      = ENV["MQTT_PASSWORD"]
    @keepalive = ENV.fetch("MQTT_KEEPALIVE", "30").to_i
    @client_id = ENV.fetch("MQTT_CLIENT_ID", "rails_mqtt_bridge_#{SecureRandom.hex(3)}")
  end

  def run!
    loop do
      begin
        @logger.info("[MQTT] Connecting #{@host}:#{@port} as #{@client_id}")
        MQTT::Client.connect(host: @host, port: @port, username: @user, password: @pass, keep_alive: @keepalive, client_id: @client_id) do |c|
          TOPICS.each { |t| c.subscribe(t) }
          @logger.info("[MQTT] Subscribed: #{TOPICS.join(", ")}")

          c.get do |topic, payload|
            handle_message(topic, payload)
          end
        end
      rescue => e
        @logger.error("[MQTT] Connection error: #{e.class}: #{e.message}")
        sleep 3
      end
    end
  end

  private

  def handle_message(topic, payload)
    data = JSON.parse(payload) rescue nil
    return unless data

    device_id   = data["device_id"].to_s.strip
    sensor_type = data["sensor_type"].to_s.downcase
    duration    = data["duration"]
    status      = data["status"]
    field_id    = data["field_id"] # opcional, se o gateway souber

    return if device_id.blank?

    sensor = Sensor.find_or_initialize_by(device_id: device_id)
    sensor.name  ||= device_id
    sensor.status ||= "Active"

    # subir para irrigation se vier indicado; nunca baixar
    if sensor_type == "irrigation"
      sensor.sensor_type = "irrigation"
      sensor.type        = "IrrigationSensor"
    elsif sensor.sensor_type.blank?
      if %w[temperature moisture].include?(sensor_type)
        sensor.sensor_type = sensor_type
        sensor.type        = "TemperatureSensor"
      else
        sensor.sensor_type ||= "sensor"
        sensor.type        ||= "Sensor"
      end
    end

    sensor.field_id = field_id if field_id.present?

    sensor.battery      = data["battery"] if data.key?("battery")
    sensor.signal       = data["signal"]  if data.key?("signal")
    sensor.last_reading = Time.current
    sensor.save!

    if duration
      IrrigationLog.create!(
        sensor_id:   sensor.id,
        device_id:   device_id,
        executed_at: data["executed_at"].present? ? Time.zone.parse(data["executed_at"]) : Time.current,
        duration:    duration.to_i,
        status:      status.presence || "executado"
      )
      sensor.update(last_value: "#{duration.to_i}s", status: "Active", last_reading: Time.current)
    end

    @logger.info("[MQTT] OK topic=#{topic} device=#{device_id} type=#{sensor.sensor_type} dur=#{duration.inspect}")
  rescue => e
    @logger.error("[MQTT] Handle error: #{e.class}: #{e.message} payload=#{payload}")
  end
end
