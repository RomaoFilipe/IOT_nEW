class IrrigationChannel < ApplicationCable::Channel
  def subscribed
    stream_from "irrigation_status"
  end
end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
