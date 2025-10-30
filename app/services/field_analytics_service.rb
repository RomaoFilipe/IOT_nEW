# app/services/field_analytics_service.rb
class FieldAnalyticsService
  # Dá prioridade às tuas colunas reais
  HUM_COLUMNS  = %w[hum_air humidity humidity_pct humidity_percent]
  TEMP_COLUMNS = %w[temp_c temperature temperature_c]
  SOIL_COLUMNS = %w[soil_pct soil_moisture soil_moisture_pct soil_humidity]
  LUX_COLUMNS  = %w[lux light]
  TS_COLUMNS   = %w[measured_at recorded_at read_at timestamp created_at]

  def initialize(field, from:, to:, sensor_id: nil)
    @field     = field
    @from      = from.to_date.beginning_of_day
    @to        = to.to_date.end_of_day
    @sensor_id = sensor_id.presence

    cols       = SensorReading.column_names
    @hum_col   = HUM_COLUMNS.find  { |c| cols.include?(c) }
    @temp_col  = TEMP_COLUMNS.find { |c| cols.include?(c) }
    @soil_col  = SOIL_COLUMNS.find { |c| cols.include?(c) }
    @lux_col   = LUX_COLUMNS.find  { |c| cols.include?(c) }
    @uptime_col= cols.include?("uptime") ? "uptime" : nil
    @errors_col= cols.include?("error_count") ? "error_count" : nil
    @ts_col    = TS_COLUMNS.find   { |c| cols.include?(c) } || "created_at"
  end

  def call
    scope = base_scope

    {
      avg_humidity: avg(scope, @hum_col),        # %
      max_temp:     max(scope, @temp_col),       # °C
      min_temp:     min(scope, @temp_col),       # °C
      uptime_pct:   uptime_pct(scope),           # %
      alerts_count: total_errors(scope),         # somatório de error_count (ou 0)
      series:       build_series(scope),
      alerts_by_type: [],                        # preenche se tiveres tabela Alerts
      last_events:    []                         # idem
    }
  end

  private

  def base_scope
    s = SensorReading.joins(:sensor)
                     .where(sensors: { field_id: @field.id })
                     .where(@ts_col => @from..@to)
    s = s.where(sensor_id: @sensor_id) if @sensor_id
    s
  end

  # KPI helpers
  def avg(scope, col) ; col ? scope.average(col).to_f : 0.0 ; end
  def max(scope, col) ; col ? scope.maximum(col).to_f : 0.0 ; end
  def min(scope, col) ; col ? scope.minimum(col).to_f : 0.0 ; end

  # Uptime: minutos distintos com leituras / total de minutos no intervalo
  # (se tiveres uma métrica melhor, ajusta aqui)
  def uptime_pct(scope)
    return 0.0 unless @ts_col
    minutes_with = scope.distinct.count(Arel.sql("date_trunc('minute', #{@ts_col})"))
    total_minutes = ((@to - @from) / 60).to_i
    return 0.0 if total_minutes <= 0
    ((minutes_with.to_f / total_minutes) * 100.0).round(1)
  end

  def total_errors(scope)
    return 0 unless @errors_col
    scope.sum(@errors_col).to_i
  end

  # Séries para gráficos (devolve só o que existir)
  def build_series(scope)
    ordered = scope.order(@ts_col)

    times        = ordered.pluck(@ts_col)
    temperature  = @temp_col ? ordered.pluck(@temp_col) : []
    humidity     = @hum_col  ? ordered.pluck(@hum_col)  : []
    soil_moist   = @soil_col ? ordered.pluck(@soil_col) : []
    # opcional: luz para futuros gráficos/insights
    lux          = @lux_col  ? ordered.pluck(@lux_col)  : []

    rows = scope
      .select("date_trunc('day', #{@ts_col}) AS day, COUNT(*) AS c")
      .group("day").order("day")

    days          = rows.map { |r| r.day.to_date.strftime("%d/%m") }
    count_per_day = rows.map { |r| r.c.to_i }

    {
      times: times,
      temperature: temperature,
      humidity: humidity,
      soil_moisture: soil_moist,
      lux: lux,
      days: days,
      count_per_day: count_per_day
    }
  end
end
