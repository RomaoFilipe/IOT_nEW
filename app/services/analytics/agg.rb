# app/services/analytics/agg.rb
module Analytics
  class Agg
    def self.call(company:, kind:, period:)
      new(company, kind, period).call
    end

    def initialize(company, kind, period)
      @company = company
      @kind    = (kind.presence || "agriculture").to_s
      @period  = (period.presence || "30d").to_s
      @tz      = Time.zone
      @from, @to = compute_range(@period)
    end

    def call
      {
        domain: @kind,
        kpis:   kpis,
        charts: charts,
        updated_at: Time.zone.now.iso8601
      }
    end

    private

    # ----------------------- IDs / Range -----------------------

    def field_ids
      @field_ids ||= Field.where(account_id: @company.id).pluck(:id)
    end

    def sensor_ids
      @sensor_ids ||= Sensor.where(field_id: field_ids).pluck(:id)
    end

    def compute_range(p)
      to = Time.zone.now.end_of_day
      from =
        case p
        when "7d"     then (to - 6.days)
        when "quarter" then (to - 3.months + 1.day)
        when "year"    then (to - 1.year + 1.day)
        else                (to - 29.days)
        end.beginning_of_day
      [from, to]
    end

    def days
      (@from.to_date..@to.to_date).to_a
    end

    def day_labels
      days.map { |d| d.strftime("%d/%m") }
    end

    def q(col)
      ActiveRecord::Base.connection.quote_column_name(col)
    end

    def date_expr(col)
      "DATE(#{q(col)})"
    end

    # ----------------------- Colunas temporais -----------------------

    def sr_time_col
      cols  = SensorReading.column_names
      scope = SensorReading.where(sensor_id: sensor_ids)
      if cols.include?("measured_at") && scope.where.not(measured_at: nil).exists?
        "measured_at"
      elsif cols.include?("read_at") && scope.where.not(read_at: nil).exists?
        "read_at"
      else
        "created_at"
      end
    end

    def ar_time_col(model, prefers)
      cols = model.column_names
      prefers.find { |c| cols.include?(c) } || "created_at"
    end

    # ----------------------- Helpers de agregação -----------------------

    def daily_average(model, scope:, time_col:, value_col:)
      rows = scope.where("#{q(time_col)} BETWEEN ? AND ?", @from, @to)
                  .group(Arel.sql(date_expr(time_col)))
                  .average(value_col)
      days.map { |d| v = rows[d]; v ? v.to_f.round(2) : nil }
    end

    def daily_sum(model, scope:, time_col:, value_col:)
      rows = scope.where("#{q(time_col)} BETWEEN ? AND ?", @from, @to)
                  .group(Arel.sql(date_expr(time_col)))
                  .sum(value_col)
      days.map { |d| v = rows[d]; v ? v.to_f.round(2) : 0 }
    end

    def safe_sum(scope, col)
      scope.sum(col).to_f
    end

    def safe_avg(scope, col)
      v = scope.average(col)
      v&.to_f
    end

    # ----------------------- Séries ambientais -----------------------

    def soil_series
      value_col =
        if SensorReading.column_names.include?("soil_pct") then "soil_pct"
        elsif SensorReading.column_names.include?("moisture") then "moisture"
        else nil
        end
      return { name: "Humidade do Solo", data: [] } unless value_col

      rel = SensorReading.where(sensor_id: sensor_ids)
      {
        name: "Humidade do Solo",
        data: daily_average(SensorReading, scope: rel, time_col: sr_time_col, value_col: value_col)
      }
    end

    def air_temp_series
      value_col =
        if SensorReading.column_names.include?("air_temperature") then "air_temperature"
        elsif SensorReading.column_names.include?("temperature")   then "temperature"
        else nil
        end
      return { name: "Temperatura do Ar", data: [] } unless value_col

      rel = SensorReading.where(sensor_id: sensor_ids)
      {
        name: "Temperatura do Ar",
        data: daily_average(SensorReading, scope: rel, time_col: sr_time_col, value_col: value_col)
      }
    end

    def air_hum_series
      value_col = SensorReading.column_names.include?("air_humidity") ? "air_humidity" : nil
      return { name: "Humidade do Ar", data: [] } unless value_col

      rel = SensorReading.where(sensor_id: sensor_ids)
      {
        name: "Humidade do Ar",
        data: daily_average(SensorReading, scope: rel, time_col: sr_time_col, value_col: value_col)
      }
    end

    def irrigation_series
      return { name: "Irrigação (min)", data: [] } unless defined?(IrrigationLog)

      time_col = ar_time_col(IrrigationLog, %w[executed_at created_at])
      rel = IrrigationLog.where(sensor_id: sensor_ids)
      {
        name: "Irrigação (min)",
        data: daily_sum(IrrigationLog, scope: rel, time_col: time_col, value_col: "duration"),
        type: "bar"
      }
    end

    # ----------------------- KPIs -----------------------

    def kpis
      total =
        if @kind == "agriculture"
          safe_sum(CropYield.where(field_id: field_ids, created_at: @from..@to), :amount)
        else
          # Para aquacultura: usa oxigénio médio como "total" aproximação
          safe_avg(AquacultureReading.where(field_id: field_ids, measured_at: @from..@to), :oxygen_level) || 0
        end

      f_time = ar_time_col(Financial, %w[recorded_at created_at])
      costs  = safe_sum(Financial.where(field_id: field_ids).where("#{q(f_time)} BETWEEN ? AND ?", @from, @to), :expenses)

      eff = gauge_value.round(1)
      qual = water_quality_pct.round(1)

      {
        total: total.round(2),
        efficiency_pct: eff,
        costs_eur: costs.round(2),
        water_quality_pct: qual
      }
    end

    def avg_soil_pct
      col =
        if SensorReading.column_names.include?("soil_pct") then "soil_pct"
        elsif SensorReading.column_names.include?("moisture") then "moisture"
        else nil
        end
      return nil unless col

      rel = SensorReading.where(sensor_id: sensor_ids)
                         .where("#{q(sr_time_col)} BETWEEN ? AND ?", @from, @to)
      safe_avg(rel, col)
    end

    def water_quality_pct
      if @kind == "agriculture"
        v = avg_soil_pct
        return 0.0 unless v
        target = 30.0 # humidade de referência
        score  = 100.0 - ((v - target).abs / target * 100.0)
        [[score, 0].max, 100].min
      else
        # aquacultura: oxigénio 8 mg/L ~ 100%
        oxy = safe_avg(AquacultureReading.where(field_id: field_ids, measured_at: @from..@to), :oxygen_level)
        return 0.0 unless oxy
        [[(oxy / 8.0) * 100.0, 0].max, 100].min
      end
    end

    def gauge_value
      water_quality_pct # por agora igual; podes combinar mais métricas se quiseres
    end

    # ----------------------- Gráficos principais -----------------------

    def line_chart
      if @kind == "agriculture"
        rel   = CropYield.where(field_id: field_ids, created_at: @from..@to)
        rows  = rel.group(Arel.sql("DATE(#{q('created_at')})")).sum(:amount)
        data  = days.map { |d| rows[d]&.to_f || 0 }
        { categories: day_labels, series: [{ name: "Produção", data: data }] }
      else
        # Aquacultura: temperatura da água e oxigénio ao longo do tempo (se existir)
        time_col = ar_time_col(AquacultureReading, %w[measured_at created_at])
        rel      = AquacultureReading.where(field_id: field_ids)
        temp  = daily_average(AquacultureReading, scope: rel, time_col: time_col, value_col: "temperature")
        oxy   = daily_average(AquacultureReading, scope: rel, time_col: time_col, value_col: "oxygen_level")
        { categories: day_labels, series: [
            { name: "Temp. Água", data: temp },
            { name: "Oxigénio",    data: oxy }
          ] }
      end
    end

    def bars_chart
      # Despesas por categoria (últimos N dias)
      time_col = ar_time_col(Financial, %w[recorded_at created_at])
      rel = Financial.where(field_id: field_ids).where("#{q(time_col)} BETWEEN ? AND ?", @from, @to)
      rows = rel.group(:expense_category).sum(:expenses)
      cats = rows.keys.compact
      vals = cats.map { |c| rows[c].to_f.round(2) }
      { categories: cats, series: [{ name: "Despesas", data: vals }] }
    end

    def donut_chart
      time_col = ar_time_col(Financial, %w[recorded_at created_at])
      rel = Financial.where(field_id: field_ids).where("#{q(time_col)} BETWEEN ? AND ?", @from, @to)
      rows = rel.group(:expense_category).sum(:expenses)
      cats = rows.keys.compact
      vals = cats.map { |c| rows[c].to_f.round(2) }
      { labels: cats, data: vals }
    end

    def charts
      {
        line:  line_chart,
        bars:  bars_chart,
        donut: donut_chart,
        gauge: { value: gauge_value.round(0) },
        # extras (ambientais)
        extra1: { categories: day_labels, series: [soil_series] },
        extra2: { categories: day_labels, series: [air_temp_series] },
        extra3: { categories: day_labels, series: [air_hum_series] },
        extra4: { categories: day_labels, series: [irrigation_series], type: "bar" }
      }
    end
  end
end
