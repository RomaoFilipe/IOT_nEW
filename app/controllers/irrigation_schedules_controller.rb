# == app/controllers/irrigation_schedules_controller.rb ==
class IrrigationSchedulesController < ApplicationController
  before_action :set_field

  def create
    days = params[:days] || []
    created = 0
  
    days.each do |day|
      schedule = @field.irrigation_schedules.new(
        sensor_id: params[:sensor_id],
        day_of_week: day,
        hour: schedule_params[:hour],
        minute: schedule_params[:minute],
        duration: schedule_params[:duration]
      )
      created += 1 if schedule.save
    end
  
    if created > 0
      redirect_back fallback_location: fields_path, notice: "Criado(s) #{created} agendamento(s)."
    else
      redirect_back fallback_location: fields_path, alert: "Erro ao criar agendamento."
    end
  end

  def destroy
    @schedule = IrrigationSchedule.find(params[:id])
    @schedule.destroy
    redirect_back fallback_location: fields_path, notice: "Agendamento removido."
  end

  private

  def set_field
    @field = Field.find(params[:field_id])
  end

  def schedule_params
    params.require(:irrigation_schedule).permit(:hour, :minute, :duration)
  end
end