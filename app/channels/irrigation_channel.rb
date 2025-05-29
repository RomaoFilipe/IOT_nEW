class IrrigationChannel < ApplicationCable::Channel
  def subscribed
    sensor_id = params[:sensor_id]
    stream_from "irrigation_#{sensor_id}"
  end
end
