# app/controllers/api/irrigation_logs_controller.rb
class Api::IrrigationLogsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_token!

  def create
    sensor = Sensor.find_by(device_id: params[:device_id])

    unless sensor
      render json: { error: "Sensor não encontrado" }, status: :not_found and return
    end

    IrrigationLog.create!(
      sensor: sensor,
      device_id: sensor.device_id,
      executed_at: Time.zone.parse(params[:executed_at]) || Time.current,
      duration: params[:duration],
      status: params[:status] || "irrigando"
    )

    sensor.update!(
      last_reading: Time.current,
      status: "irrigando"
    )

    render json: { message: "Log criado com sucesso" }, status: :created
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def authenticate_token!
    token = request.headers["Authorization"].to_s.split(" ").last
    unless token.present? && ActiveSupport::SecurityUtils.secure_compare(token, ENV["API_TOKEN"])
      render json: { error: "Token inválido" }, status: :unauthorized
    end
  end
end
