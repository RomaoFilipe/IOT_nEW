# app/controllers/api/irrigation_logs_controller.rb
class Api::IrrigationLogsController < ApplicationController
skip_before_action :authenticate_user!
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

  def start_irrigation
    @irrigation = IrrigationLog.find(params[:id])
    @irrigation.update!(status: 'Em andamento', started_at: Time.current)

    render json: { message: "Irrigação iniciada", remaining_time: @irrigation.remaining_time }
  end

  def remaining_time
    total_time = self.duration # em segundos
    elapsed_time = Time.current - self.started_at
    remaining_time = total_time - elapsed_time
    remaining_time > 0 ? remaining_time : 0
  end

# Adicione Turbo Stream para atualização em tempo real
def irrigation_status
  irrigation_log = IrrigationLog.find_by(sensor_id: params[:sensor_id])
  remaining_time = irrigation_log.remaining_time # Calculado no backend
  total_duration = irrigation_log.total_duration

  respond_to do |format|
    format.turbo_stream { render turbo_stream: turbo_stream.replace('irrigation-progress', partial: 'irrigation_status', locals: { remaining_time: remaining_time, total_time: total_duration }) }
    format.json { render json: { remaining_time: remaining_time, total_time: total_duration } }
  end
end


  private

  def authenticate_token!
    token = request.headers["Authorization"].to_s.split(" ").last
    unless token.present? && token == "abc123supersecreto"
      render json: { error: "Token inválido" }, status: :unauthorized
    end
  end
end
