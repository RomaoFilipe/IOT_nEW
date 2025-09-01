# app/controllers/analytics_controller.rb
class AnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_account!
  before_action :set_kind!

  # Página HTML
  def index; end

  # GET /analytics/data?period=7d|30d|quarter|year
  def data
    period = params[:period].presence_in(%w[7d 30d quarter year]) || "7d"
    from, to = window_for(period)

    # Campos desta conta (com filtro tolerante ao formato guardado na BD)
    fields = Field.where(account_id: @account.id)
    if Field.column_names.include?("production_kind") && @kind.present?
      # normaliza na query: lower(replace(production_kind,' ','_')) = @kind
      fields = fields.where(Arel.sql("LOWER(REPLACE(production_kind,' ','_')) = ?"), @kind)
    end
    fids = fields.pluck(:id)
    return render json: empty_payload, status: :ok if fids.empty?

    # Domínios a partir do @kind (normalizado)
    has_agri      = (@kind == "agriculture")
    has_aqua_tank = (@kind == "aquaculture_tank")
    has_aqua_sea  = (@kind == "aquaculture_sea")

    # Sensores desses campos
    sids = Sensor.where(field_id: fids).pluck(:id)

    # --------- AGRICULTURA (só se for o domínio atual) ----------
    kpi_soil = kpi_airt = kpi_airh = nil
    last_soil = nil
    line  = { categories: [], series: [] }
    bars  = { categories: [], series: [] }
    donut = { labels: [], data: [] }

    if has_agri && sids.any?
      readings = SensorReading.where(sensor_id: sids)
                              .where(Arel.sql("#{SensorReading.ts_sql} BETWEEN :from AND :to"), from: from, to: to)

      kpi_soil = readings.average(:soil_pct)&.to_f&.round(2)
      kpi_airt = readings.average(Arel.sql(SensorReading.air_temp_sql))&.to_f&.round(2)
      kpi_airh = readings.average(Arel.sql(SensorReading.air_hum_sql))&.to_f&.round(2)

      last_soil = readings.order(Arel.sql("#{SensorReading.ts_sql} DESC")).limit(1).pick(:soil_pct)&.to_f&.round(2)

      daily_rows = readings
        .group(Arel.sql("DATE(#{SensorReading.ts_sql})"))
        .pluck(
          Arel.sql("DATE(#{SensorReading.ts_sql}) AS day"),
          Arel.sql("AVG(soil_pct)"),
          Arel.sql("AVG(#{SensorReading.air_temp_sql})"),
          Arel.sql("AVG(#{SensorReading.air_hum_sql})"),
          Arel.sql("AVG(lux)")
        ).sort_by { |d, *_| d }

      line = {
        categories: daily_rows.map { |d, *_| d.to_date.strftime("%d/%m") },
        series: [
          { name: "Humidade do Solo (%)",   data: daily_rows.map { |_, v, *_| v&.to_f&.round(2) } },
          { name: "Temperatura do Ar (°C)", data: daily_rows.map { |_, _, v, *_| v&.to_f&.round(2) } },
          { name: "Humidade do Ar (%)",     data: daily_rows.map { |_, _, _, v, _| v&.to_f&.round(2) } },
          { name: "Luz (lux)",              data: daily_rows.map { |_, _, _, _, v| v&.to_f&.round(0) } }
        ]
      }

      # Barras de rega: prefere IrrigationLog (histórico real). Fallback: executed_at em schedule.
      if ActiveRecord::Base.connection.data_source_exists?("irrigation_logs")
        irrig_rows = IrrigationLog.joins(:sensor)
                                  .where(sensors: { field_id: fids })
                                  .where(executed_at: from..to)
                                  .group(Arel.sql("DATE(executed_at)"))
                                  .pluck(Arel.sql("DATE(executed_at) AS day"), Arel.sql("COALESCE(SUM(duration),0)"))
                                  .sort_by { |d, *_| d }
      else
        irrig_rows = IrrigationSchedule.for_fields(fids)
                                       .executed_between(from, to)
                                       .group(Arel.sql("DATE(executed_at)"))
                                       .pluck(Arel.sql("DATE(executed_at) AS day"), Arel.sql("COALESCE(SUM(duration),0)"))
                                       .sort_by { |d, *_| d }
      end

      bars = {
        categories: irrig_rows.map { |d, _| d.to_date.strftime("%d/%m") },
        series: [{ name: "Minutos de rega", data: irrig_rows.map { |_, m| m.to_i } }]
      }

      donut_dist   = readings.group(:sensor_id).pluck(:sensor_id, Arel.sql("AVG(soil_pct)"))
      sensor_names = Sensor.where(id: donut_dist.map(&:first)).pluck(:id, :name).to_h
      donut = {
        labels: donut_dist.map { |sid, _| sensor_names[sid].presence || "Sensor ##{sid}" },
        data:   donut_dist.map { |_, avg| avg&.to_f&.round(2) || 0 }
      }
    end

    # --------- AQUACULTURA: TANQUES ----------
    aqua_tank_line = { categories: [], series: [] }
    if has_aqua_tank
      tank_fids  = fields.pluck(:id) # já estão filtrados ao domínio
      tank_scope = AquacultureReading.for_fields(tank_fids).between(from, to)
      if tank_scope.exists?
        rows = tank_scope.group(Arel.sql("DATE(measured_at)"))
                         .pluck(
                           Arel.sql("DATE(measured_at) AS day"),
                           Arel.sql("AVG(temperature)"),
                           Arel.sql("AVG(ph)"),
                           Arel.sql("AVG(salinity)"),
                           Arel.sql("AVG(oxygen_level)")
                         ).sort_by { |d, *_| d }
        aqua_tank_line = {
          categories: rows.map { |d, *_| d.to_date.strftime("%d/%m") },
          series: [
            { name: "Temp. Água (°C)",   data: rows.map { |_, v, *_| v&.to_f&.round(2) } },
            { name: "pH",                data: rows.map { |_, _, v, *_| v&.to_f&.round(2) } },
            { name: "Salinidade (ppt)",  data: rows.map { |_, _, _, v, _| v&.to_f&.round(2) } },
            { name: "Oxigénio (mg/L)",   data: rows.map { |_, _, _, _, v| v&.to_f&.round(2) } }
          ]
        }
      end
    end

    # --------- AQUACULTURA: MAR ----------
    aqua_sea_line = { categories: [], series: [] }
    if has_aqua_sea
      sea_fids  = fields.pluck(:id) # já filtrados ao domínio
      sea_scope = AquacultureReading.for_fields(sea_fids).between(from, to)
      if sea_scope.exists?
        rows = sea_scope.group(Arel.sql("DATE(measured_at)"))
                        .pluck(
                          Arel.sql("DATE(measured_at) AS day"),
                          Arel.sql("AVG(temperature)"),
                          Arel.sql("AVG(ph)"),
                          Arel.sql("AVG(salinity)"),
                          Arel.sql("AVG(oxygen_level)")
                        ).sort_by { |d, *_| d }
        aqua_sea_line = {
          categories: rows.map { |d, *_| d.to_date.strftime("%d/%m") },
          series: [
            { name: "Temp. Mar (°C)",    data: rows.map { |_, v, *_| v&.to_f&.round(2) } },
            { name: "pH",                data: rows.map { |_, _, v, *_| v&.to_f&.round(2) } },
            { name: "Salinidade (ppt)",  data: rows.map { |_, _, _, v, _| v&.to_f&.round(2) } },
            { name: "Oxigénio (mg/L)",   data: rows.map { |_, _, _, _, v| v&.to_f&.round(2) } }
          ]
        }
      end
    end

    # Próximas regas (apenas faz sentido em agricultura; mas enviamos sempre)
    upcoming = IrrigationSchedule.for_fields(fids).upcoming.first(5).map do |ir|
      { day_of_week: ir.day_of_week, time: ir.time_hhmm, duration: ir.duration, sensor_id: ir.sensor_id }
    end

    payload = {
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
        aqua_tank: aqua_tank_line,
        aqua_sea:  aqua_sea_line
      },
      irrigation: { upcoming: upcoming }
    }

    response.set_header("Cache-Control", "max-age=10, public")
    render json: payload, status: :ok
  rescue => e
    Rails.logger.error("[Analytics#data] #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    render json: { error: "Falha ao gerar analytics." }, status: :unprocessable_entity
  end

  # Export CSV simples
  def export
    period = params[:period].presence_in(%w[7d 30d quarter year]) || "7d"
    from, to = window_for(period)

    sids = Sensor.where(field_id: current_user.account.fields.select(:id)).pluck(:id)
    rows = SensorReading.where(sensor_id: sids)
                        .where(Arel.sql("#{SensorReading.ts_sql} BETWEEN :from AND :to"), from: from, to: to)
                        .order(Arel.sql("#{SensorReading.ts_sql} ASC"))
                        .pluck(:sensor_id, :soil_pct, :temp_c, :air_temperature, :hum_air, :air_humidity, :lux, :measured_at, :read_at, :created_at)

    csv = +"sensor_id,soil_pct,temp_c,air_temperature,hum_air,air_humidity,lux,measured_at,read_at,created_at\n"
    rows.each { |r| csv << r.map { |v| v.is_a?(Time) ? v.iso8601 : v }.join(",") << "\n" }
    send_data csv, filename: "analytics_#{Time.zone.now.strftime('%Y%m%d_%H%M')}.csv"
  end

private

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

def set_account!
  @account = current_user.account
  head :forbidden unless @account
end

def set_kind!
  acc_kind   = normalize_kind(@account&.production_kind)
  inferred   = infer_kind_from_fields

  if acc_kind.present? && Field.column_names.include?("production_kind")
    has_for_acc = Field.where(account_id: @account.id)
                       .where(Arel.sql("LOWER(REPLACE(production_kind,' ','_')) = ?"), acc_kind)
                       .exists?
    @kind = has_for_acc ? acc_kind : (inferred || "agriculture")
  else
    @kind = acc_kind.presence || inferred || "agriculture"
  end
end


  # --------- Payload vazio ---------
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
      irrigation: { upcoming: [] }
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
end
