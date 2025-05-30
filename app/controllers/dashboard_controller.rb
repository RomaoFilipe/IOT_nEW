class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @fields = current_user.fields
    @field = params[:field_id] ? current_user.fields.find_by(id: params[:field_id]) : current_user.fields.first

    now = Time.current
    today_wday = now.wday

    # Tarefas planeadas futuras associadas a campos do utilizador
    planned_tasks = PlannedTask
      .includes(:field)
      .where(completed: false)
      .where("scheduled_for >= ?", now)
      .where(field: current_user.fields) # Segurança: só campos do user
      .map do |task|
        {
          id: task.id,
          type: :task,
          title: task.title,
          description: task.description,
          field: task.field&.name,
          time: task.scheduled_for,
          priority: task.priority
        }
      end

    # Irrigações agendadas para hoje nos sensores dos campos do user
    irrigation_schedules = IrrigationSchedule
      .includes(sensor: :field)
      .where(day_of_week: today_wday)
      .select { |s| s.sensor&.field && current_user.fields.include?(s.sensor.field) }
      .map do |schedule|
        scheduled_time = Time.zone.local(
          now.year, now.month, now.day, schedule.hour, schedule.minute
        )
  
        {
          id: schedule.id,
          type: :irrigation,
          title: "Irrigação - #{schedule.sensor.name}",
          description: "#{schedule.duration}s",
          field_id: schedule.sensor.field.id,    # Importante para rota aninhada
          field: schedule.sensor.field.name,
          time: scheduled_time
        }
      end
      .select { |e| e[:time] >= now }  # Apenas eventos futuros ou agora

    # Junta tudo e ordena pela data/hora do evento
    @events = (planned_tasks + irrigation_schedules).sort_by { |e| e[:time] }
  end
end
