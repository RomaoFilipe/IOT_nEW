class SensorChannel < ApplicationCable::Channel
  def subscribed
    stream_from "sensor_updates"
  end

  def unsubscribed
    # Qualquer limpeza se necessário
  end
end
