# app/controllers/api/irrigation_logs_controller.rb
module Api
  class IrrigationLogsController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      sensor = Sensor.find_by(device_id: params[:device_id])
      if sensor
        IrrigationLog.create!(
          sensor: sensor,
          executed_at: Time.at(params[:timestamp] || Time.now.to_i),
          duration: params[:duration].to_i,
          status: params[:status] || "executado"
        )
        render json: { success: true }, status: :created
      else
        render json: { error: "Sensor não encontrado" }, status: :not_found
      end
    end
  end
end
