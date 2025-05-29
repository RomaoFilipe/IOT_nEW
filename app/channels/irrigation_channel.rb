class IrrigationChannel < ApplicationCable::Channel
  def subscribed
    if params[:sensor_id].present?
      Rails.logger.debug "📡 Subscrito ao canal: irrigation_#{params[:sensor_id]}"
      stream_from "irrigation_#{params[:sensor_id]}"
    else
      Rails.logger.debug "📡 Subscrito ao canal: irrigation_channel (geral)"
      stream_from "irrigation_channel"
    end
  end
  
end
