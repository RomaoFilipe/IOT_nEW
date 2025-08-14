class DashboardController < ApplicationController
  before_action :authenticate_user!

  # janelas e limites (ajusta à vontade)
  ONLINE_WINDOW_MINUTES = 10
  MAX_UPCOMING_EVENTS   = 50
  MAX_SENSOR_READINGS   = 10

  def index
    account_id = current_user.account_id

    # Campos do utilizador (com preload de sensores para evitar N+1 nas secções abaixo)
    @fields = Field.where(account_id: account_id)
                   .includes(:sensors) # usado em "Estado de Irrigação" e noutros blocos
                   .order(:name)

    # KPIs agregados num único hash (usado pela view)
    @kpis = {
      fields:            @fields.size, # já temos @fields carregados
      sensors_total:     sensors_total_count(account_id),
      sensors_online:    sensors_online_count(account_id),
      irrigations_today: count_irrigations_today_for_account(account_id),
      alerts_open:       alerts_open_count(account_id)
    }

    # Estado de irrigação por campo (apenas sensores de irrigação) — evita N+1 porque @fields inclui :sensors
    @irrigation_sensors_by_field = @fields.to_h do |f|
      [f, f.sensors.select { |s| s.sensor_type == "irrigation" }]
    end

    # Feed de atividade — apenas da empresa do utilizador
    @sensor_readings = build_sensor_readings_feed(account_id, MAX_SENSOR_READINGS)
  end

  # Endpoint JSON já existente
  def upcoming_events
    now = Time.zone.now

    planned_tasks = []
    if defined?(PlannedTask) && PlannedTask.reflect_on_association(:field)
      planned_tasks = PlannedTask.joins(:field)
                                 .where(fields: { account_id: current_user.account_id })
                                 .where("planned_at >= ?", now)
                                 .order(:planned_at)
                                 .limit(MAX_UPCOMING_EVENTS)
                                 .select(:id, :title, :description, :planned_at, :field_id)
                                 .map do |t|
        {
          id: t.id,
          type: 'task',
          title: t.title,
          description: t.description,
          field_id: t.field_id,
          field: t.field&.name,
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

    # Usa escopo/enum :online se existir; senão, tenta status; senão, last_seen_at; senão 0
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
      scope.count # fallback (se não houver estado, conta todos)
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
      # Sem `date`/`scheduled_at`: assumir hour/minute e (opcionalmente) day_of_week
      scope = scope.where(day_of_week: Time.zone.today.wday) if col?(IrrigationSchedule, :day_of_week)
      scope.count
    end
  end

  def build_irrigation_events(now)
    return [] unless defined?(IrrigationSchedule)

    scope = IrrigationSchedule.joins(sensor: :field).where(fields: { account_id: current_user.account_id })
    have_scheduled_at = col?(IrrigationSchedule, :scheduled_at)
    have_hour         = col?(IrrigationSchedule, :hour)
    have_minute       = col?(IrrigationSchedule, :minute)

    records =
      if have_scheduled_at
        scope.where("scheduled_at >= ?", now).order(:scheduled_at).limit(MAX_UPCOMING_EVENTS)
      elsif have_hour && have_minute
        # Sem datetime: aproximação — traz algumas e construímos o próximo horário
        scope.limit(200)
      else
        []
      end

    records.map do |schedule|
      time =
        if have_scheduled_at
          schedule.scheduled_at&.in_time_zone
        elsif have_hour && have_minute
          t = Time.zone.local(now.year, now.month, now.day, schedule.hour, schedule.minute)
          t = t + 1.day if t < now # garantir próximo futuro
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

  # ———— Feed de atividade ————

  def build_sensor_readings_feed(account_id, limit)
    return [] unless defined?(SensorReading)

    SensorReading
      .joins(sensor: :field)
      .where(fields: { account_id: account_id })
      .order(created_at: :desc)
      .limit(limit)
      .includes(sensor: :field) # para evitar N+1 na view
  end
end
