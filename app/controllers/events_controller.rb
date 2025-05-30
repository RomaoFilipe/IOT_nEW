class EventsController < ApplicationController
  # Temporariamente ignora autenticação só nesta action para teste
  skip_before_action :authenticate_user!, only: [:upcoming]

  def upcoming
    now = Time.current
    today_wday = now.wday

    planned_tasks = PlannedTask
      .includes(:field)
      .where(completed: false)
      .where("scheduled_for >= ?", now)
      .where(field: current_user ? current_user.fields : Field.all) # Se current_user existir filtra, senão retorna tudo
      .map do |task|
        {
          id: task.id,
          type: 'task',
          title: task.title,
          field: task.field&.name,
          time: task.scheduled_for,
          priority: task.priority
        }
      end

    irrigation_schedules = IrrigationSchedule
      .includes(sensor: :field)
      .where(day_of_week: today_wday)
      .select { |s| s.sensor&.field }
      .map do |schedule|
        scheduled_time = Time.zone.local(
          now.year, now.month, now.day, schedule.hour, schedule.minute
        )

        {
          id: schedule.id,
          type: 'irrigation',
          title: "Irrigação - #{schedule.sensor.name}",
          description: "#{schedule.duration}s",
          field_id: schedule.sensor.field.id,
          field: schedule.sensor.field.name,
          time: scheduled_time
        }
      end
      .select { |e| e[:time] >= now }

    events = (planned_tasks + irrigation_schedules).sort_by { |e| e[:time] }

    render json: { events: events }
  end
end
