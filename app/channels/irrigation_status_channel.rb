# app/channels/irrigation_status_channel.rb
class IrrigationStatusChannel < ApplicationCable::Channel
  def subscribed
    stream_from "irrigation_status_\#{params[:sensor_id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
