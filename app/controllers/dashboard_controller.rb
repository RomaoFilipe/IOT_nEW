# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    account_id = current_user.account_id

    # Campos do utilizador
    @fields = Field.where(account_id: account_id)
                   .includes(:sensors)
                   .order(:name)

    # KPIs agregados num único hash (usado pela view)
    @kpis = {
      fields: @fields.size,
      sensors_total: sensors_total_count(account_id),
      sensors_online: sensors_online_count(account_id),
      irrigations_today: count_irrigations_today_for_account(account_id),
      alerts_open: alerts_open_count(account_id)
    }

    # Estado de irrigação por campo (apenas sensores de irrigação)
    @irrigation_sensors_by_field = @fields.to_h do |f|
      [f, f.sensors.select { |s| s.sensor_type == "irrigation" }]
    end
  end

  # Endpoint JSON já existente
  def upcoming_events
    now = Time.zone.now

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

    irrigation_schedules = build_irrigation_events(now)
    events = (planned_tasks + irrigation_schedules).sort_by { |e| e[:time] }

    respond_to do |format|
      format.json { render json: { events: events } }
    end
  end

  private

  # ———— Contagens auxiliares ————

  def sensors_base_scope(account_id)
    Sensor.joins(:field).where(fields: { account_id: account_id })
  end

  def sensors_total_count(account_id)
    sensors_base_scope(account_id).count
  end

  def sensors_online_count(account_id)
    scope = sensors_base_scope(account_id)

    # Tenta usar enum/escopo :online se existir; caso contrário assume coluna status ou last_seen_at
    if Sensor.respond_to?(:online) # escopo class-level
      scope.merge(Sensor.online).count
    elsif Sensor.column_names.include?("status")
      scope.where(status: "online").count
    elsif Sensor.column_names.include?("last_seen_at")
      scope.where("last_seen_at >= ?", 10.minutes.ago).count
    else
      0
    end
  end

  def alerts_open_count(account_id)
    return 0 unless defined?(Alert)

    scope = Alert.joins(:field).where(fields: { account_id: account_id })
    if Alert.column_names.include?("status")
      scope.where(status: "open").count
    elsif Alert.column_names.include?("resolved")
      scope.where(resolved: false).count
    else
      scope.count # fallback (se não houver estado, conta todos)
    end
  end

  # ———— Helpers flexíveis para diferentes esquemas de irrigação ————

  def count_irrigations_today_for_account(account_id)
    scope = IrrigationSchedule.joins(sensor: :field).where(fields: { account_id: account_id })

    if IrrigationSchedule.column_names.include?("date")
      scope.where(date: Date.current).count
    elsif IrrigationSchedule.column_names.include?("scheduled_at")
      scope.where(scheduled_at: Time.zone.today.all_day).count
    else
      # Sem `date`/`scheduled_at`: assumir hour/minute e (opcionalmente) day_of_week
      scope = scope.where(day_of_week: Time.zone.today.wday) if IrrigationSchedule.column_names.include?("day_of_week")
      scope.count
    end
  end

  def build_irrigation_events(now)
    scope = IrrigationSchedule.joins(sensor: :field).where(fields: { account_id: current_user.account_id })
    have_scheduled_at = IrrigationSchedule.column_names.include?("scheduled_at")
    have_hour   = IrrigationSchedule.column_names.include?("hour")
    have_minute = IrrigationSchedule.column_names.include?("minute")

    records =
      if have_scheduled_at
        scope.where("scheduled_at >= ?", now).order(:scheduled_at).limit(50)
      elsif have_hour && have_minute
        scope.limit(200) # sem datetime: aproximação
      else
        []
      end

    records.map do |schedule|
      time =
        if have_scheduled_at
          schedule.scheduled_at.in_time_zone
        elsif have_hour && have_minute
          t = Time.zone.local(now.year, now.month, now.day, schedule.hour, schedule.minute)
          t = t + 1.day if t < now # <— agora aplica mesmo o +1.day
          t
        end

      next unless time && time >= now

      {
        id: schedule.id,
        type: 'irrigation',
        title: "Irrigação - #{schedule.sensor&.name || schedule.sensor_id}",
        description: (schedule.try(:duration).present? ? "#{schedule.duration}s" : nil),
        field_id: schedule.sensor&.field_id,
        field: schedule.sensor&.field&.name,
        time: time
      }
    end.compact
  end
end
