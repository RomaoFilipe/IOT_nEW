# app/controllers/events_controller.rb
class EventsController < ApplicationController
  def upcoming
    now     = Time.zone.now
    today   = now.to_date
    horizon = now + 24.hours

    # ---------- Tarefas (próximas 24h) ----------
    tasks = PlannedTask
              .joins(:field)
              .where(completed: false)
              .where(scheduled_for: now..horizon)
              .select('planned_tasks.id, planned_tasks.title, planned_tasks.priority,
                       planned_tasks.scheduled_for, planned_tasks.field_id,
                       fields.name AS field_name')

    task_events = tasks.map do |t|
      {
        id:       t.id,
        type:     'task',
        title:    t.title.presence || I18n.t('dashboard.upcoming_tasks.untitled_task', default: 'Task'),
        field:    t.field_name,
        field_id: t.field_id,
        time:     t.scheduled_for.iso8601,
        priority: t.priority
      }
    end

    # ---------- Irrigações semanais (sem starts_at) ----------
    weekly = IrrigationSchedule
               .joins(:field, :sensor)
               .select('irrigation_schedules.id, irrigation_schedules.duration,
                        irrigation_schedules.day_of_week, irrigation_schedules.hour, irrigation_schedules.minute,
                        fields.id AS field_id, fields.name AS field_name,
                        sensors.id AS sensor_id, sensors.name AS sensor_name')

    weekly_events = weekly.filter_map do |s|
      # DB usa 0..6 (Dom..Sáb) — igual a Ruby wday
      dow        = s.day_of_week.to_i
      base_today = Time.zone.local(today.year, today.month, today.day, s.hour.to_i, s.minute.to_i)

      # próxima ocorrência para este horário
      days_ahead = (dow - now.wday) % 7
      next_at    = base_today + days_ahead.days
      next_at   += 7.days if next_at < now # se “hoje” mas já passou a hora

      # só eventos dentro do próximo dia
      if next_at <= horizon
        {
          id:         s.id,
          type:       'irrigation',
          title:      "Irrigação - #{s.sensor_name}",
          description:"#{s.duration.to_i}s",
          field:      s.field_name,
          field_id:   s.field_id,
          sensor_id:  s.sensor_id,
          duration:   s.duration.to_i,
          time:       next_at.iso8601
        }
      end
    end

    events = (task_events + weekly_events).sort_by { |e| e[:time] }
    render json: { events: events }
  end
end
