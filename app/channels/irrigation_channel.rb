class IrrigationChannel < ApplicationCable::Channel
  def subscribed
    if params[:sensor_id].present?
      stream_from "irrigation_#{params[:sensor_id]}"
    else
      stream_from "irrigation_channel"
    end
  end
end
