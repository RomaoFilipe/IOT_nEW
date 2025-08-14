class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    # Campos do utilizador
    @fields = Field.where(account_id: current_user.account_id)
                   .includes(:sensors)
                   .order(:name)

    # KPIs: sensores
    sensors_scope = Sensor.joins(:field).where(fields: { account_id: current_user.account_id })
    @sensors_total  = sensors_scope.count
    @sensors_online = sensors_scope.respond_to?(:online) ? sensors_scope.online.count : 0

    # KPI: irrigações “hoje” — tentar diferentes esquemas sem assumir a coluna `date`
    @irrigations_today_count = count_irrigations_today_for_account(current_user.account_id)

    # Lista “Estado de Irrigação” por campo (só sensores de irrigação)
    @irrigation_sensors_by_field = @fields.map do |f|
      [f, f.sensors.where(sensor_type: "irrigation").to_a]
    end.to_h
  end

  # Endpoint JSON que já tinhas
  def upcoming_events
    now = Time.zone.now

    # Tarefas planeadas (se existir modelo/associação)
    planned_tasks = []
    if defined?(PlannedTask) && PlannedTask.reflect_on_association(:field)
      planned_tasks = PlannedTask.joins(:field)
                                 .where(fields: { account_id: current_user.account_id })
                                 .where("planned_at >= ?", now)
                                 .select("planned_tasks.id, planned_tasks.title, planned_tasks.description, planned_tasks.planned_at, planned_tasks.field_id")
                                 .map do |t|
        {
          id: t.id,
          type: 'task',
          title: t.title,
          description: t.description,
          field_id: t.field_id,
          field: t.field.name,
          time: t.planned_at
        }
      end
    end

    # Irrigação (funciona quer tenhas `scheduled_at`, quer `hour/minute[/day_of_week]`)
    irrigation_schedules = build_irrigation_events(now)

    events = (planned_tasks + irrigation_schedules).sort_by { |e| e[:time] }

    respond_to do |format|
      format.json { render json: { events: events } }
    end
  end

  private

  # ————— Helpers flexíveis para diferentes esquemas —————

  def count_irrigations_today_for_account(account_id)
    scope = IrrigationSchedule.joins(sensor: :field).where(fields: { account_id: account_id })

    if IrrigationSchedule.column_names.include?("date")
      scope.where(date: Date.current).count
    elsif IrrigationSchedule.column_names.include?("scheduled_at")
      scope.where(scheduled_at: Time.zone.today.all_day).count
    else
      # Sem `date`/`scheduled_at`: assumir hour/minute e (opcionalmente) day_of_week
      dow = Time.zone.today.wday
      scope = scope.where(day_of_week: dow) if IrrigationSchedule.column_names.include?("day_of_week")
      scope.count
    end
  end

  def build_irrigation_events(now)
    scope = IrrigationSchedule.joins(sensor: :field).where(fields: { account_id: current_user.account_id })
    have_scheduled_at = IrrigationSchedule.column_names.include?("scheduled_at")
    have_hour         = IrrigationSchedule.column_names.include?("hour")
    have_minute       = IrrigationSchedule.column_names.include?("minute")

    records =
      if have_scheduled_at
        scope.where("scheduled_at >= ?", now).order(:scheduled_at).limit(50)
      elsif have_hour && have_minute
        # Sem datetime: pegar próximos 24h aproximados
        scope.limit(200)
      else
        [] # esquema desconhecido
      end

    records.map do |schedule|
      time =
        if have_scheduled_at
          schedule.scheduled_at.in_time_zone
        elsif have_hour && have_minute
          Time.zone.local(now.year, now.month, now.day, schedule.hour, schedule.minute).tap do |t|
            # se já passou hoje, assume amanhã à mesma hora
            t + 1.day if t < now
          end
        end

      next unless time && time >= now

      {
        id: schedule.id,
        type: 'irrigation',
        title: "Irrigação - #{schedule.sensor&.name || schedule.sensor_id}",
        description: schedule.try(:duration).present? ? "#{schedule.duration}s" : nil,
        field_id: schedule.sensor&.field_id,
        field: schedule.sensor&.field&.name,
        time: time
      }
    end.compact
  end
end
