# == app/controllers/irrigation_schedules_controller.rb ==
class IrrigationSchedulesController < ApplicationController
  before_action :set_field
  

  def create
    days = params[:days] || []
    slider_steps = params[:irrigation_schedule][:duration_slider].to_i
    duration = slider_steps * 30 * 60  # ← converte para segundos
    created = 0
  
    days.each do |day|
      schedule = @field.irrigation_schedules.new(
        schedule_params.merge(
          day_of_week: day.to_i,
          duration: duration  # ← força override aqui
        )
      )
  
      created += 1 if schedule.save
    end
  
    if created > 0
      redirect_back fallback_location: fields_path, notice: "Criado(s) #{created} agendamento(s)."
    else
      redirect_back fallback_location: fields_path, alert: "Erro ao criar agendamento."
    end
  end
  

  def today
    @field = Field.find(params[:field_id])
    now = Time.zone.now
  
    @schedules = @field.irrigation_schedules
      .where(day_of_week: now.wday)
      .where("hour > ? OR (hour = ? AND minute > ?)", now.hour, now.hour, now.min)
      .order(:hour, :minute)
  end
  
  def destroy
    irrigation_schedule = IrrigationSchedule.find(params[:id])
    irrigation_schedule.destroy
    respond_to do |format|
      format.html { redirect_to irrigation_schedules_path, notice: "Irrigação cancelada com sucesso." }
      format.turbo_stream
    end
  end
  

  def destroy
    @schedule = IrrigationSchedule.find(params[:id])
    @schedule.destroy
    redirect_to dashboard_path, notice: "Agendamento de irrigação removido com sucesso."
  end

  private

  def set_field
    @field = Field.find(params[:field_id])
  end

  def schedule_params
    params.require(:irrigation_schedule).permit(:hour, :minute, :sensor_id)
  end
end
