class SensorReadingsChannel < ApplicationCable::Channel
  def subscribed
    sensor = Sensor.find(params[:id])
    stream_for sensor
  end

  def unsubscribed
    # Cleanup logic se necessário
  end
end
