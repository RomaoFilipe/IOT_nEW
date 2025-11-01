# app/services/field_analytics_service.rb
class FieldAnalyticsService
  # Dá prioridade às tuas colunas reais
HUM_COLUMNS  = %w[hum_air air_humidity humidity humidity_pct humidity_percent].freeze
TEMP_COLUMNS = %w[temp_c temperature temperature_c].freeze
SOIL_COLUMNS = %w[soil_pct soil_moisture soil_moisture_pct soil_humidity moisture].freeze
LUX_COLUMNS  = %w[lux light].freeze
TS_COLUMNS   = %w[measured_at recorded_at read_at timestamp created_at].freeze

  # granularity: '5m' (teste) | '1h' (prod). Default: '1h'
  def initialize(field, from:, to:, sensor_id: nil, granularity: '1h')
    @field      = field
    @from       = to_time(from)&.beginning_of_day || 24.hours.ago
    @to         = to_time(to)&.end_of_day         || Time.current
    @sensor_id  = sensor_id.presence
    @gran       = %w[5m 1h].include?(granularity) ? granularity : '1h'

    cols        = SensorReading.column_names
    @hum_col    = HUM_COLUMNS.find  { |c| cols.include?(c) }
    @temp_col   = TEMP_COLUMNS.find { |c| cols.include?(c) }
    @soil_col   = SOIL_COLUMNS.find { |c| cols.include?(c) }
    @lux_col    = LUX_COLUMNS.find  { |c| cols.include?(c) }
    @uptime_col = cols.include?("uptime") ? "uptime" : nil
    @errors_col = cols.include?("error_count") ? "error_count" : nil
    @ts_col     = TS_COLUMNS.find   { |c| cols.include?(c) } || "created_at"
  end

  def call
    scope = base_scope

    {
      avg_humidity: avg(scope, @hum_col),        # %
      max_temp:     max(scope, @temp_col),       # °C
      min_temp:     min(scope, @temp_col),       # °C
      uptime_pct:   uptime_pct(scope),           # %
      alerts_count: total_errors(scope),         # somatório de error_count (ou 0)
      series:       build_series_grouped(scope), # ⬅️ agora agrega por 5m/1h
      alerts_by_type: [],
      last_events:    []
    }
  end

  private

  def to_time(v)
    return v if v.is_a?(Time)
    return v.to_time if v.respond_to?(:to_time)
    Time.zone.parse(v.to_s) rescue nil
  end

  def base_scope
    s = SensorReading
          .joins(:sensor)
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
  def uptime_pct(scope)
    return 0.0 unless @ts_col
    minutes_with  = scope.distinct.count(Arel.sql("date_trunc('minute', #{@ts_col})"))
    total_minutes = ((@to - @from) / 60).to_i
    return 0.0 if total_minutes <= 0
    ((minutes_with.to_f / total_minutes) * 100.0).round(1)
  end

  def total_errors(scope)
    return 0 unless @errors_col
    scope.sum(@errors_col).to_i
  end

  # --- NOVO: séries agregadas por bucket (5m ou 1h) ---
  def build_series_grouped(scope)
    bucket_sql =
      case @gran
      when '5m' then "to_timestamp(floor(extract(epoch from #{@ts_col})/300)*300)"
      else           "date_trunc('hour', #{@ts_col})"
      end

    # SELECT dinâmico só com colunas existentes (evita erros de SQL)
    select_bits = []
    select_bits << "#{bucket_sql} AT TIME ZONE 'Europe/Lisbon' AS ts_pt"
    select_bits << "AVG(#{@temp_col})   AS temp_c_avg"   if @temp_col
    select_bits << "AVG(#{@hum_col})    AS hum_air_avg"  if @hum_col
    select_bits << "AVG(#{@soil_col})   AS soil_pct_avg" if @soil_col
    select_bits << "AVG(#{@lux_col})    AS lux_avg"      if @lux_col
    select_bits << "COUNT(*)            AS count"

    rows = scope
      .select(select_bits.join(", "))
      .group("1")
      .order("1 ASC")

    # Constrói arrays para o gráfico (labels + séries)
    times = []
    temp  = []
    hum   = []
    soil  = []
    lux   = []
    cnt   = []

    rows.each do |r|
      times << r.read_attribute("ts_pt")
      temp  << r.read_attribute("temp_c_avg")   if @temp_col
      hum   << r.read_attribute("hum_air_avg")  if @hum_col
      soil  << r.read_attribute("soil_pct_avg") if @soil_col
      lux   << r.read_attribute("lux_avg")      if @lux_col
      cnt   << r.read_attribute("count")
    end

    {
      times: times,                   # Array<Time> PT
      temperature: @temp_col ? temp : [],
      humidity:    @hum_col  ? hum  : [],
      soil_moisture: @soil_col ? soil : [],
      lux:         @lux_col  ? lux  : [],
      bucket:      @gran,            # '5m' | '1h'
      count_per_bucket: cnt          # pontos por bucket
    }
  end
end
