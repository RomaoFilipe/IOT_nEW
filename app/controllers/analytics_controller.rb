# app/controllers/analytics_controller.rb
class AnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_account!
  before_action :set_field_if_present!   # suporta contexto por Field
  before_action :set_kind!               # usa o kind do Field se existir

  helper_method :current_domain

  # ===========================
  # Página HTML “global”
  # ===========================
  def index
    # Campos da conta (para o select)
    @fields = @account.fields.select(:id, :name).order(:name)

    # Hash { field_id => [{id:, name:}, ...] } para preencher multiselect de sensores no cliente
    @sensors_by_field =
      @account.fields.includes(:sensors).each_with_object({}) do |f, h|
        h[f.id] = f.sensors.select(:id, :name).map { |s| { id: s.id, name: (s.name.presence || "Sensor ##{s.id}") } }
      end

    # Sensores “soltos” (sem field) que pertencem à conta (ajusta conforme o teu modelo)
    orphan = Sensor.where(field_id: nil)
                   .joins("JOIN fields ON fields.account_id = #{@account.id}")
                   .limit(0) # salvaguarda: desativado; ativa se precisares
    @sensors_by_field[0] = orphan.select(:id, :name).map { |s| { id: s.id, name: (s.name.presence || "Sensor ##{s.id}") } }
  end

  # ===========================
  # JSON para a página (ApexCharts)
  # GET /analytics/data
  # ===========================
  def data
    period = params[:period].presence_in(%w[7d 30d quarter year]) || "7d"
    res    = params[:res].presence || "5m"

    payload = build_payload(period: period, field_id: params[:field_id], res: res)

    response.set_header("Cache-Control", "max-age=10, public")
    render json: payload, status: :ok
  rescue => e
    Rails.logger.error("[Analytics#data] #{e.class}: #{e.message}\n#{e.backtrace&.first(6)&.join("\n")}")
    render json: { error: "Falha ao gerar analytics." }, status: :unprocessable_entity
  end

  # ===========================
  # PDF do relatório
  # GET /analytics/report.pdf
  # ===========================
  def report
    period   = params[:period].presence || "7d"
    field_id = params[:field_id].presence
    res      = params[:res].presence || "5m"

    @field = field_id.present? ? current_user.account.fields.find_by(id: field_id) : nil

    # usa o mesmo payload do JSON
    @data = build_payload(period: period, field_id: field_id, res: res)

    # fallback opcional: se não houver séries no período, tenta últimos 7 dias
    line = @data.dig(:charts, :line) || {}
    if (Array(line[:series]).blank? || Array(line[:categories]).blank?) && period != "7d"
      @data = build_payload(period: "7d", field_id: field_id, res: res)
      @data[:meta] ||= {}
      @data[:meta][:note] = "Sem dados no período selecionado; mostram-se últimos 7 dias."
    end

    respond_to do |format|
      format.pdf do
        # Opcional: cabeçalho/rodapé HTML (parciais)
        header_html = render_to_string(partial: "shared/pdf_header", locals: { field: @field, data: @data }) rescue nil
        footer_html = render_to_string(partial: "shared/pdf_footer") rescue nil

        render pdf:  (@field ? "relatorio_#{@field.name.parameterize}" : "relatorio_analytics"),
               layout:   "pdf",
               template: "analytics/report",
               encoding: "UTF-8",
               disposition: "attachment",
               header: (header_html ? { content: header_html } : {}),
               footer: (footer_html ? { content: footer_html } : {}),
               margin: { top: 22, bottom: 18, left: 12, right: 12 }
      end
    end
  end

  # ===========================
  # Export CSV “bruto”
  # GET /analytics/export(.csv)
  # ===========================
  def export
    period = params[:period].presence_in(%w[7d 30d quarter year]) || "7d"
    from, to = window_for(period)

    scope_fields = current_user.account.fields
    scope_fields = scope_fields.where(id: params[:field_id]) if params[:field_id].present?
    sids = Sensor.where(field_id: scope_fields.select(:id)).pluck(:id)

    rows = SensorReading.where(sensor_id: sids)
                        .where(Arel.sql("#{SensorReading.ts_sql} BETWEEN :from AND :to"), from: from, to: to)
                        .order(Arel.sql("#{SensorReading.ts_sql} ASC"))
                        .pluck(:sensor_id, :soil_pct, :temp_c, :air_temperature, :hum_air, :air_humidity, :lux, :measured_at, :read_at, :created_at)

    csv = +"sensor_id,soil_pct,temp_c,air_temperature,hum_air,air_humidity,lux,measured_at,read_at,created_at\n"
    rows.each { |r| csv << r.map { |v| v.is_a?(Time) ? v.iso8601 : v }.join(",") << "\n" }
    send_data csv, filename: "analytics_#{Time.zone.now.strftime('%Y%m%d_%H%M')}.csv"
  end

  # ===========================
  # Privados / Helpers
  # ===========================
  private

  def current_domain = @kind

  def set_account!
    @account = current_user.account
    head :forbidden unless @account
  end

  # Se vier field_id, valida e define @field
  def set_field_if_present!
    return unless params[:field_id].present?
    @field = Field.where(account_id: @account.id).find_by(id: params[:field_id])
    head :forbidden and return unless @field
  end

  # Normalização de “kind”
  def normalize_kind(value)
    v = value.to_s.strip.downcase.tr(" ", "_")
    case v
    when "agricultura"       then "agriculture"
    when "aquacultura_tank"  then "aquaculture_tank"
    when "aquacultura_sea"   then "aquaculture_sea"
    else v
    end
  end

  def infer_kind_from_fields
    return nil unless Field.column_names.include?("production_kind")
    kinds = Field.where(account_id: @account.id)
                 .pluck(:production_kind)
                 .compact
                 .map { |v| normalize_kind(v) }
    return nil if kinds.empty?
    kinds.group_by(&:itself).max_by { |_k, v| v.size }&.first
  end

  def set_kind!
    if @field&.respond_to?(:production_kind) && @field.production_kind.present?
      @kind = normalize_kind(@field.production_kind)
      return
    end

    acc_kind = normalize_kind(@account&.production_kind)
    inferred = infer_kind_from_fields

    if acc_kind.present? && Field.column_names.include?("production_kind")
      has_for_acc = Field.where(account_id: @account.id)
                         .where(Arel.sql("LOWER(REPLACE(production_kind,' ','_')) = ?"), acc_kind)
                         .exists?
      @kind = has_for_acc ? acc_kind : (inferred || "agriculture")
    else
      @kind = acc_kind.presence || inferred || "agriculture"
    end
  end

  # --------- Payload vazio (estrutura base) ---------
  def empty_payload
    {
      domain: @kind,
      updated_at: Time.zone.now,
      kpis: { avg_soil_pct: nil, avg_air_temp: nil, avg_air_hum: nil },
      charts: {
        line:       { categories: [], series: [] },
        bars:       { categories: [], series: [] },
        donut:      { labels: [], data: [] },
        gauge:      { value: nil },
        aqua_tank:  { categories: [], series: [] },
        aqua_sea:   { categories: [], series: [] }
      },
      irrigation: { upcoming: [] },
      meta: { period: "7d", res: "5m" }
    }
  end

  # --------- Janela temporal ---------
  def window_for(period)
    to = Time.zone.now
    from =
      case period
      when "7d"      then 7.days.ago.beginning_of_day
      when "30d"     then 30.days.ago.beginning_of_day
      when "quarter" then 3.months.ago.beginning_of_day
      when "year"    then 1.year.ago.beginning_of_day
      else                 7.days.ago.beginning_of_day
      end
    [from, to]
  end

  # --------- helpers locais ---------
  def want_to_keys(want)
    arr = []
    arr << "soil" if want.include?("soil")
    arr << "airt" if want.include?("temp")
    arr << "airh" if want.include?("hum")
    arr << "lux"  if want.include?("lux")
    arr
  end

  def truthy?(v) = ["1", "true", "on", true].include?(v)

  # suavização simples (média móvel)
  def smooth(arr, win = 3)
    return arr unless arr.is_a?(Array) && arr.compact.size >= win
    out = []
    arr.each_with_index do |_, i|
      w = arr[[0, i - (win - 1)].max..i].compact
      out << (w.empty? ? nil : (w.sum / w.size.to_f))
    end
    out
  end

  # ===========================
  # Núcleo partilhado (HTML/JSON e PDF)
  # ===========================
  def build_payload(period:, field_id:, res:)
    period = period.presence_in(%w[7d 30d quarter year]) || "7d"
    from, to = window_for(period)

    # fields no contexto da conta (+ filtro field_id se existir)
    fields = Field.where(account_id: @account.id)
    if field_id.present?
      f = fields.find_by(id: field_id)
      return empty_payload.merge(updated_at: Time.zone.now, meta: { period: period, res: res }) unless f
      fields = fields.where(id: f.id)
    else
      if !@field && Field.column_names.include?("production_kind") && @kind.present?
        fields = fields.where(Arel.sql("LOWER(REPLACE(production_kind,' ','_')) = ?"), @kind)
      end
    end

    fids = fields.pluck(:id)
    return empty_payload.merge(updated_at: Time.zone.now, meta: { period: period, res: res }) if fids.empty?

    has_agri = (@kind == "agriculture")
    sids = Sensor.where(field_id: fids).pluck(:id)

    # base do payload
    kpi_soil = kpi_airt = kpi_airh = nil
    last_soil = nil
    line  = { categories: [], series: [] }
    bars  = { categories: [], series: [] }
    donut = { labels: [], data: [] }

    if has_agri && sids.any?
      # filtros extra
      if params[:sensor_ids].present?
        only = Array(params[:sensor_ids]).map(&:to_i)
        sids &= only
      end
      return empty_payload.merge(updated_at: Time.zone.now, meta: { period: period, res: res }) if sids.empty?

      # resolução
      allowed  = { "5m" => 300, "15m" => 900, "1h" => 3600, "day" => 86_400 }
      step_sec = allowed[res.to_s] || ((period == "7d" || period == "30d") ? 300 : 3600)

      # agregação
      agg_fn = case params[:agg].to_s
               when "min" then "MIN"
               when "max" then "MAX"
               else            "AVG"
               end

      want = Array(params[:metric]).presence || %w[soil temp hum lux]

      ts_sql   = SensorReading.ts_sql
      soil_sql = (SensorReading.soil_sql     if want.include?("soil"))
      at_sql   = (SensorReading.air_temp_sql if want.include?("temp"))
      ah_sql   = (SensorReading.air_hum_sql  if want.include?("hum"))
      lx_sql   = (SensorReading.lux_sql      if want.include?("lux"))

      selects = []
      selects << "#{agg_fn}(#{soil_sql}) AS soil" if soil_sql
      selects << "#{agg_fn}(#{at_sql})   AS airt" if at_sql
      selects << "#{agg_fn}(#{ah_sql})   AS airh" if ah_sql
      selects << "#{agg_fn}(#{lx_sql})   AS lux"  if lx_sql

      bucket_expr = "to_timestamp(floor(extract(epoch from #{ts_sql})/#{step_sec})*#{step_sec})"
      sids_list   = sids.join(",")

      series_sql = ActiveRecord::Base.send(:sanitize_sql_array, [
        "SELECT gs AS bucket FROM generate_series(?, ?, (? || ' seconds')::interval) gs",
        from, to, step_sec
      ])

      agg_sql = <<~SQL
        SELECT #{bucket_expr} AS bucket, #{selects.join(", ")}
        FROM sensor_readings
        WHERE sensor_id IN (#{sids_list})
          AND #{ts_sql} BETWEEN #{ActiveRecord::Base.connection.quote(from)}
                            AND #{ActiveRecord::Base.connection.quote(to)}
        GROUP BY bucket
      SQL

      final_sql = <<~SQL
        WITH series AS (#{series_sql}),
             agg AS (#{agg_sql})
        SELECT series.bucket, #{(%w[soil airt airh lux] & want_to_keys(want)).map { |k| "agg.#{k}" }.join(", ")}
        FROM series
        LEFT JOIN agg ON agg.bucket = series.bucket
        ORDER BY series.bucket
      SQL

      rows = ActiveRecord::Base.connection.exec_query(final_sql).to_a

      readings = SensorReading.where(sensor_id: sids)
                              .where(Arel.sql("#{ts_sql} BETWEEN :from AND :to"), from: from, to: to)
      kpi_soil = readings.average(Arel.sql(SensorReading.soil_sql))&.to_f&.round(2)  if want.include?("soil")
      kpi_airt = readings.average(Arel.sql(SensorReading.air_temp_sql))&.to_f&.round(2) if want.include?("temp")
      kpi_airh = readings.average(Arel.sql(SensorReading.air_hum_sql))&.to_f&.round(2)  if want.include?("hum")

      last_soil = if want.include?("soil")
        readings.order(Arel.sql("#{ts_sql} DESC")).limit(1).pluck(Arel.sql(SensorReading.soil_sql)).first&.to_f&.round(2)
      end

      categories = rows.map { |r| r["bucket"]&.in_time_zone&.strftime("%d/%m %H:%M") }

      series = []
      if want.include?("soil")
        soil = rows.map { |r| r["soil"]&.to_f }
        soil = smooth(soil, 3) if truthy?(params[:smooth])
        series << { name: "Humidade do Solo (%)",   data: soil }
      end
      if want.include?("temp")
        airt = rows.map { |r| r["airt"]&.to_f }
        airt = smooth(airt, 3) if truthy?(params[:smooth])
        series << { name: "Temperatura do Ar (°C)", data: airt }
      end
      if want.include?("hum")
        airh = rows.map { |r| r["airh"]&.to_f }
        airh = smooth(airh, 3) if truthy?(params[:smooth])
        series << { name: "Humidade do Ar (%)",     data: airh }
      end
      if want.include?("lux")
        lux = rows.map { |r| r["lux"]&.to_f }
        lux = smooth(lux, 3) if truthy?(params[:smooth])
        series << { name: "Luz (lux)",              data: lux }
      end

      line = { categories: categories, series: series }

      # Barras (rega) em MINUTOS (a partir de segundos)
      if ActiveRecord::Base.connection.data_source_exists?("irrigation_logs")
        irrig_rows = IrrigationLog.joins(:sensor)
                                  .where(sensors: { field_id: fids })
                                  .where(executed_at: from..to)
                                  .group(Arel.sql("DATE(executed_at)"))
                                  .pluck(
                                    Arel.sql("DATE(executed_at) AS day"),
                                    Arel.sql("COALESCE(SUM(duration) / 60.0, 0)")
                                  )
                                  .sort_by { |d, *_| d }
      else
        irrig_rows = IrrigationSchedule.for_fields(fids)
                                       .executed_between(from, to)
                                       .group(Arel.sql("DATE(executed_at)"))
                                       .pluck(
                                         Arel.sql("DATE(executed_at) AS day"),
                                         Arel.sql("COALESCE(SUM(duration) / 60.0, 0)")
                                       )
                                       .sort_by { |d, *_| d }
      end

      bars = {
        categories: irrig_rows.map { |d, _| d.to_date.strftime("%d/%m") },
        series: [{ name: "Minutos de Rega", data: irrig_rows.map { |_, m| m.to_f.round(2) } }]
      }

      # Donut: média de solo por sensor (no período)
      donut = if want.include?("soil")
        dist = readings.group(:sensor_id)
                       .pluck(:sensor_id, Arel.sql("AVG(#{SensorReading.soil_sql})"))
        sensor_names = Sensor.where(id: dist.map(&:first)).pluck(:id, :name).to_h
        {
          labels: dist.map { |sid, _| sensor_names[sid].presence || "Sensor ##{sid}" },
          data:   dist.map { |_, avg| avg&.to_f&.round(2) || 0 }
        }
      else
        { labels: [], data: [] }
      end
    end

    {
      domain: @kind,
      updated_at: Time.zone.now,
      kpis: {
        avg_soil_pct: kpi_soil,
        avg_air_temp: kpi_airt,
        avg_air_hum:  kpi_airh
      },
      charts: {
        line:      line,
        bars:      bars,
        donut:     donut,
        gauge:     { value: last_soil },
        aqua_tank: { categories: [], series: [] },
        aqua_sea:  { categories: [], series: [] }
      },
      irrigation: { upcoming: [] },
      meta: { period: period, res: res }
    }
  end
end
