class DashboardController < ApplicationController
  before_action :authenticate_user!

  # janelas e limites (ajusta à vontade)
  ONLINE_WINDOW_MINUTES = 10
  MAX_UPCOMING_EVENTS   = 50
  MAX_SENSOR_READINGS   = 30

  def index
    account_id = current_user.account_id

    # Campos do utilizador (com preload para evitar N+1)
    @fields = Field.where(account_id: account_id)
                   .includes(:sensors)
                   .order(:name)

    # KPIs
    @kpis = {
      fields:            @fields.size,
      sensors_total:     sensors_total_count(account_id),
      sensors_online:    sensors_online_count(account_id),
      irrigations_today: count_irrigations_today_for_account(account_id),
      alerts_open:       alerts_open_count(account_id)
    }

    # Sensores de irrigação por campo
    @irrigation_sensors_by_field = @fields.to_h do |f|
      [f, f.sensors.select { |s| s.sensor_type == "irrigation" }]
    end

    # Próximos eventos (tarefas + regas)
    @events = build_upcoming_events(account_id: account_id, horizon_hours: 24)

    # Feed (se usares na vista)
    @sensor_readings = build_sensor_readings_feed(account_id, MAX_SENSOR_READINGS)
  end

def activity_feed
  per  = params[:per].presence&.to_i || 12
  per  = per.clamp(6, 60)
  page = params[:page].presence&.to_i || 1
  page = 1 if page < 1

  base = SensorReading
           .joins(sensor: :field)
           .where(fields: { account_id: current_user.account_id })

  @total  = base.count
  @pages  = (@total / per.to_f).ceil
  @page   = page
  @per    = per

  order_sql = Arel.sql("#{SensorReading.ts_sql} DESC")
  readings = base
               .includes(sensor: :field)
               .order(order_sql)
               .offset((page - 1) * per)
               .limit(per)

  render partial: "dashboard/activity_grid", locals: {
    readings: readings, page: @page, per: @per, total: @total, pages: @pages
  }
end


  # Endpoint JSON (opcional; reutiliza a mesma lógica do painel)
  def upcoming_events
    account_id = current_user.account_id
    events = build_upcoming_events(account_id: account_id, horizon_hours: 24)

    render json: {
      events: events.map { |e|
        {
          id:          e[:id],
          type:        e[:type],
          title:       e[:title],
          description: e[:description],
          field_id:    e[:field_id],
          field:       e[:field],
          time:        e[:time].iso8601
        }
      }
    }
  end

  private

  # ———— Utilitários ————
  def col?(model_klass, column_name)
    model_klass.column_names.include?(column_name.to_s)
  rescue
    false
  end

  # ———— Sensores / Alertas ————
  def sensors_base_scope(account_id)
    Sensor.joins(:field).where(fields: { account_id: account_id })
  end

  def sensors_total_count(account_id)
    sensors_base_scope(account_id).count
  end

  def sensors_online_count(account_id)
    scope = sensors_base_scope(account_id)

    if Sensor.respond_to?(:online)
      scope.merge(Sensor.online).count
    elsif col?(Sensor, :status)
      scope.where(status: "online").count
    elsif col?(Sensor, :last_seen_at)
      scope.where("last_seen_at >= ?", ONLINE_WINDOW_MINUTES.minutes.ago).count
    else
      0
    end
  end

  def alerts_open_count(account_id)
    return 0 unless defined?(Alert)

    scope = Alert.joins(:field).where(fields: { account_id: account_id })

    if col?(Alert, :status)
      scope.where(status: "open").count
    elsif col?(Alert, :resolved)
      scope.where(resolved: false).count
    else
      scope.count
    end
  end

  # ———— Irrigação ————
  def count_irrigations_today_for_account(account_id)
    scope = IrrigationSchedule.joins(sensor: :field).where(fields: { account_id: account_id })

    if col?(IrrigationSchedule, :date)
      scope.where(date: Date.current).count
    elsif col?(IrrigationSchedule, :scheduled_at)
      scope.where(scheduled_at: Time.zone.today.all_day).count
    else
      scope = scope.where(day_of_week: Time.zone.today.wday) if col?(IrrigationSchedule, :day_of_week)
      scope.count
    end
  end

  # Junta tarefas (scheduled_for) + regas HOJE a partir de agora; e também as próximas 24h
  def build_upcoming_events(account_id:, horizon_hours: 24)
    now     = Time.zone.now
    today   = now.to_date
    horizon = now + horizon_hours.hours

    fields_scope = Field.where(account_id: account_id).select(:id)

    # ---- TAREFAS (schema: scheduled_for, completed) ----
    task_events =
      PlannedTask.joins(:field)
                 .where(fields: { id: fields_scope })
                 .where(completed: false)
                 .where(scheduled_for: now..horizon)
                 .select('planned_tasks.id, planned_tasks.title, planned_tasks.priority,
                          planned_tasks.scheduled_for, planned_tasks.field_id,
                          fields.name AS field_name')
                 .map do |t|
        {
          id:          t.id,
          type:        'task',
          title:       t.title.presence || 'Task',
          field:       t.field_name,
          field_id:    t.field_id,
          time:        t.scheduled_for,
          priority:    t.priority,
          description: nil
        }
      end

    # ---- IRRIGAÇÕES (HOJE e >= agora) ----
    wday = now.wday
    irrigation_today =
      IrrigationSchedule
        .joins(:field, :sensor)
        .where(fields: { id: fields_scope })
        .where(day_of_week: wday)
        .where(
          "(irrigation_schedules.hour > :h) OR (irrigation_schedules.hour = :h AND irrigation_schedules.minute >= :m)",
          h: now.hour, m: now.min
        )
        .select('irrigation_schedules.id, irrigation_schedules.duration,
                 irrigation_schedules.hour, irrigation_schedules.minute,
                 irrigation_schedules.field_id,
                 fields.name  AS field_name,
                 sensors.id   AS sensor_id,
                 sensors.name AS sensor_name')

    irrigation_events = irrigation_today.map do |s|
      start_at = Time.zone.local(today.year, today.month, today.day, s.hour.to_i, s.minute.to_i)
      {
        id:          s.id,
        type:        'irrigation',
        title:       "Irrigação - #{s.sensor_name || s.field_name}",
        description: "#{s.duration.to_i}s",
        field:       s.field_name,
        field_id:    s.field_id,
        sensor_id:   s.sensor_id,
        duration:    s.duration.to_i,
        time:        start_at
      }
    end

    # (Opcional) Próximas 24h para além de hoje: inclui também as de amanhã se couberem na janela
    irrigation_next_24h = begin
      weekly = IrrigationSchedule
                 .joins(:field, :sensor)
                 .where(fields: { id: fields_scope })
                 .select('irrigation_schedules.id, irrigation_schedules.duration,
                          irrigation_schedules.day_of_week, irrigation_schedules.hour, irrigation_schedules.minute,
                          irrigation_schedules.field_id,
                          fields.name  AS field_name,
                          sensors.id   AS sensor_id,
                          sensors.name AS sensor_name')

      weekly.filter_map do |s|
        dow = s.day_of_week.to_i
        # próxima ocorrência >= now
        days_ahead = (dow - now.wday) % 7
        start_at   = Time.zone.local(today.year, today.month, today.day, s.hour.to_i, s.minute.to_i) + days_ahead.days
        start_at  += 7.days if start_at < now
        next unless start_at <= horizon
        {
          id:          s.id,
          type:        'irrigation',
          title:       "Irrigação - #{s.sensor_name || s.field_name}",
          description: "#{s.duration.to_i}s",
          field:       s.field_name,
          field_id:    s.field_id,
          sensor_id:   s.sensor_id,
          duration:    s.duration.to_i,
          time:        start_at
        }
      end
    end

    # Une tudo, remove duplicados pelo par (type,id) e ordena por tempo
    merged = (task_events + irrigation_events + irrigation_next_24h)
    uniq   = {}
    merged.each { |e| uniq[[e[:type], e[:id]]] ||= e }

    uniq.values.sort_by { |e| e[:time] }.first(MAX_UPCOMING_EVENTS)
  end

  # ———— Feed de atividade ————
  def build_sensor_readings_feed(account_id, limit)
    return [] unless defined?(SensorReading)

    SensorReading
      .joins(sensor: :field)
      .where(fields: { account_id: account_id })
      .order(created_at: :desc)
      .limit(limit)
      .includes(sensor: :field)
  end
end

private

def build_sensor_readings_feed(account_id, limit)
  return [] unless ActiveRecord::Base.connection.data_source_exists?("sensor_readings")

  SensorReading
    .joins("INNER JOIN sensors ON sensors.id = sensor_readings.sensor_id")
    .joins("INNER JOIN fields  ON fields.id  = sensors.field_id")
    .where("fields.account_id = ?", account_id)
    .order(Arel.sql("#{SensorReading.ts_sql} DESC"))
    .limit(limit)
    .includes(:sensor) # evita N+1 quando a view faz r.sensor
end
