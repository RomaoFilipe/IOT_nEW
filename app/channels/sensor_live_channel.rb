class SensorLiveChannel < ApplicationCable::Channel
  def subscribed
    # stream por sensor (ex.: "sensor:42:live")
    stream_from "sensor:#{params[:sensor_id]}:live"
  end
end
