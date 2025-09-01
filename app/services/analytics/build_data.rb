# frozen_string_literal: true

# Caminho: app/services/analytics/build_data.rb
# Gera o payload JSON para a view: KPIs + séries diárias
module Analytics
  class BuildData
    PERIOD_TO_DAYS = {
      "7d"     => 7,
      "30d"    => 30,
      "quarter"=> 90,
      "year"   => 365
    }.freeze

    def self.call(account:, kind:, period:)
      new(account, kind, period).call
    end

    def initialize(account, kind, period)
      @account = account
      @kind    = kind
      @period  = period.presence || "30d"
      @days    = PERIOD_TO_DAYS.fetch(@period, 30)
      @to      = Time.zone.now
      @from    = @to - @days.days
    end

    def call
      fields   = Field.where(account_id: @account.id, production_kind: @kind)
      field_ids = fields.pluck(:id)
      sensor_ids = Sensor.where(field_id: field_ids).pluck(:id)

      kpis = build_kpis(sensor_ids)
      series = build_series(sensor_ids)

      {
        domain: @kind,
        kpis: kpis,
        charts: series,
        updated_at: Time.zone.now.iso8601
      }
    end

    private

    def ts_sql
      "COALESCE(sensor_readings.measured_at, sensor_readings.read_at, sensor_readings.created_at)"
    end

    def bucket_sql
      "date_trunc('day', #{ts_sql})"
    end

    def build_kpis(sensor_ids)
      return empty_kpis if sensor_ids.empty?

      # último valor por sensor (distinct on) para calcular médias “atuais”
      rows = ActiveRecord::Base.connection.exec_query(<<~SQL)
        SELECT DISTINCT ON (r.sensor_id)
               r.sensor_id,
               r.soil_pct, r.air_temperature, r.air_humidity,
               #{ts_sql} AS ts
        FROM sensor_readings r
        WHERE r.sensor_id IN (#{sensor_ids.join(",")})
        ORDER BY r.sensor_id, ts DESC
      SQL

      soil   = pick_avg(rows, "soil_pct")
      atemp  = pick_avg(rows, "air_temperature")
      ahum   = pick_avg(rows, "air_humidity")

      # Minutos de rega no período (somatório)
      ir_minutes = IrrigationLog.where(sensor_id: sensor_ids)
                                .where("executed_at >= ?", @from)
                                .sum(:duration).to_i

      {
        "Soil moisture (%)" => round_or_nil(soil),
        "Air temperature (°C)" => round_or_nil(atemp),
        "Air humidity (%)" => round_or_nil(ahum),
        "Irrigation (min, period)" => ir_minutes
      }
    rescue
      empty_kpis
    end

    def empty_kpis
      {
        "Soil moisture (%)" => nil,
        "Air temperature (°C)" => nil,
        "Air humidity (%)" => nil,
        "Irrigation (min, period)" => 0
      }
    end

    def pick_avg(rows, key)
      vals = rows.map { |r| r[key] }.compact.map(&:to_f)
      return nil if vals.empty?
      vals.sum / vals.size
    end

    def round_or_nil(v, p = 1)
      v.nil? ? nil : v.round(p)
    end

    def build_series(sensor_ids)
      cats = days_range(@from.to_date, @to.to_date)

      {
        moisture:   build_daily_avg(sensor_ids, :soil_pct, cats),
        air_temp:   build_daily_avg(sensor_ids, :air_temperature, cats),
        air_hum:    build_daily_avg(sensor_ids, :air_humidity, cats),
        irrigation: build_irrigation(sensor_ids, cats)
      }
    end

    def days_range(from_d, to_d)
      (from_d..to_d).map { |d| d.strftime("%Y-%m-%d") }
    end

    def build_daily_avg(sensor_ids, column, categories)
      return { categories:, data: [] } if sensor_ids.empty?

      col = column.to_s
      rows = SensorReading
        .where(sensor_id: sensor_ids)
        .where("#{ts_sql} >= ?", @from)
        .group(Arel.sql(bucket_sql))
        .pluck(Arel.sql("#{bucket_sql}::date"), Arel.sql("AVG(#{col})"))

      by_day = rows.to_h.transform_keys { |d| d.strftime("%Y-%m-%d") }
      data = categories.map { |d| (by_day[d]&.to_f&.round(1)) }

      { categories: categories, data: data }
    end

    def build_irrigation(sensor_ids, categories)
      return { categories:, data: [] } if sensor_ids.empty?

      rows = IrrigationLog
        .where(sensor_id: sensor_ids)
        .where("executed_at >= ?", @from)
        .group(Arel.sql("date_trunc('day', executed_at)"))
        .pluck(Arel.sql("date_trunc('day', executed_at)::date"), Arel.sql("SUM(duration)"))

      by_day = rows.to_h.transform_keys { |d| d.strftime("%Y-%m-%d") }
      data = categories.map { |d| by_day[d]&.to_i || 0 }

      { categories: categories, data: data }
    end
  end
end

