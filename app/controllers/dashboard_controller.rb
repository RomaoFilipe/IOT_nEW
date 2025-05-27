class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @fields = Field.all
    @field = params[:field_id] ? Field.find(params[:field_id]) : Field.first

    now = Time.current
    today_wday = now.wday

    # Tarefas planeadas futuras
    planned_tasks = PlannedTask
      .includes(:field)
      .where(completed: false)
      .where("scheduled_for >= ?", now)
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

    # Irrigações agendadas para hoje e ainda por iniciar
    irrigation_schedules = IrrigationSchedule
      .includes(sensor: :field)
      .where(day_of_week: today_wday)
      .select { |s| s.sensor.present? && s.sensor.field.present? }
      .map do |schedule|
        scheduled_time = Time.zone.local(
          now.year, now.month, now.day, schedule.hour, schedule.minute
        )

        {
          id: schedule.id,
          type: :irrigation,
          title: "Irrigação - #{schedule.sensor.name}",
          description: "#{schedule.duration}s",
          field: schedule.sensor.field.name,
          time: scheduled_time
        }
      end
      .select { |e| e[:time] >= now }

    # Unir e ordenar cronologicamente
    @events = (planned_tasks + irrigation_schedules).sort_by { |e| e[:time] }
  end
end
