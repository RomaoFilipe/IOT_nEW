# app/controllers/analytics_controller.rb
class AnalyticsController < ApplicationController
  MESES_PT = %w[Jan Fev Mar Abr Mai Jun Jul Ago Set Out Nov Dez].freeze

  # -------------------------------------------------------------------
  # UI principal (server-render). Mantém a tua lógica original.
  # -------------------------------------------------------------------
  def index
    # Campos só com o que é preciso para a UI
    @fields = Field.select(:id, :name, :production_kind)

    # -------- Filtros vindos da query --------
    @selected_culture = params[:culture].presence
    @start_date = safe_parse_date(params[:start_date])
    @end_date   = safe_parse_date(params[:end_date])

    # Tipo efetivo (por campo, ou por parâmetro, ou default)
    @effective_kind =
      if params[:field_id].present?
        f = @fields.find { |x| x.id.to_s == params[:field_id].to_s }
        f&.production_kind.presence || params[:production_kind].presence || "agriculture"
      else
        params[:production_kind].presence || "agriculture"
      end

    # Culturas disponíveis (para o dropdown)
    @available_cultures = CropYield.distinct.pluck(:crop_type).compact.sort

    # -------- Scopes base por campo (quando existir) --------
    if params[:field_id].present?
      @selected_field  = Field.find_by(id: params[:field_id])
      yields_scope     = @selected_field ? @selected_field.crop_yields : CropYield.none
      @soil_data       = @selected_field ? @selected_field.soil_readings : SoilReading.none
      @financial_data  = @selected_field ? @selected_field.financials    : Financial.none
      @sensor_readings = @selected_field ? SensorReading.where(sensor: @selected_field.sensors) : SensorReading.none
    else
      yields_scope     = CropYield.all
      @soil_data       = SoilReading.all
      @financial_data  = Financial.all
      @sensor_readings = SensorReading.all
    end

    # Cultura (apenas faz sentido para Agricultura)
    yields_scope = yields_scope.where(crop_type: @selected_culture) if @selected_culture.present?

    # Datas
    if @start_date
      yields_scope     = yields_scope.where("created_at >= ?", @start_date)
      @soil_data       = @soil_data.where("measured_at >= ?", @start_date)
      @financial_data  = @financial_data.where("recorded_at >= ?", @start_date)
      @sensor_readings = @sensor_readings.where("read_at >= ?", @start_date)
    end
    if @end_date
      yields_scope     = yields_scope.where("created_at <= ?", @end_date)
      @soil_data       = @soil_data.where("measured_at <= ?", @end_date)
      @financial_data  = @financial_data.where("recorded_at <= ?", @end_date)
      @sensor_readings = @sensor_readings.where("read_at <= ?", @end_date)
    end

    # -------- Datasets por tipo de produção --------
    case @effective_kind
    when "agriculture"
      build_agriculture_datasets!(yields_scope)
    when "aquaculture_sea"
      build_aquaculture_sea_datasets!
    when "aquaculture_tank"
      build_aquaculture_tank_datasets!
    else
      # fallback: sem erros, só não renderiza gráficos
    end
  end

  # -------------------------------------------------------------------
  # Endpoint JSON para dashboards/auto-refresh
  # GET /analytics/data.json
  # Aceita os MESMOS parâmetros da index (production_kind, field_id, start_date, end_date, culture, ...)
  # -------------------------------------------------------------------
  def data
    # Reutiliza a mesma preparação de filtros/escopos da index
    @fields = Field.select(:id, :name, :production_kind)
    @selected_culture = params[:culture].presence
    @start_date = safe_parse_date(params[:start_date])
    @end_date   = safe_parse_date(params[:end_date])

    @effective_kind =
      if params[:field_id].present?
        f = @fields.find { |x| x.id.to_s == params[:field_id].to_s }
        f&.production_kind.presence || params[:production_kind].presence || "agriculture"
      else
        params[:production_kind].presence || "agriculture"
      end

    if params[:field_id].present?
      @selected_field  = Field.find_by(id: params[:field_id])
      yields_scope     = @selected_field ? @selected_field.crop_yields : CropYield.none
      @soil_data       = @selected_field ? @selected_field.soil_readings : SoilReading.none
      @financial_data  = @selected_field ? @selected_field.financials    : Financial.none
      @sensor_readings = @selected_field ? SensorReading.where(sensor: @selected_field.sensors) : SensorReading.none
    else
      yields_scope     = CropYield.all
      @soil_data       = SoilReading.all
      @financial_data  = Financial.all
      @sensor_readings = SensorReading.all
    end

    yields_scope = yields_scope.where(crop_type: @selected_culture) if @selected_culture.present?

    if @start_date
      yields_scope     = yields_scope.where("created_at >= ?", @start_date)
      @soil_data       = @soil_data.where("measured_at >= ?", @start_date)
      @financial_data  = @financial_data.where("recorded_at >= ?", @start_date)
      @sensor_readings = @sensor_readings.where("read_at >= ?", @start_date)
    end
    if @end_date
      yields_scope     = yields_scope.where("created_at <= ?", @end_date)
      @soil_data       = @soil_data.where("measured_at <= ?", @end_date)
      @financial_data  = @financial_data.where("recorded_at <= ?", @end_date)
      @sensor_readings = @sensor_readings.where("read_at <= ?", @end_date)
    end

    # Construção dos datasets e serialização JSON
    case @effective_kind
    when "agriculture"
      build_agriculture_datasets!(yields_scope)
      render json: json_agriculture, status: :ok
    when "aquaculture_sea"
      build_aquaculture_sea_datasets!
      render json: json_sea, status: :ok
    when "aquaculture_tank"
      build_aquaculture_tank_datasets!
      render json: json_tank, status: :ok
    else
      render json: { error: "production_kind inválido" }, status: :unprocessable_entity
    end
  end

  private

  # =====================
  # Agricultura
  # =====================
  def build_agriculture_datasets!(yields)
    # 📊 Produção por Cultura e Mês
    grouped = yields.group_by { |r| MESES_PT.include?(r.month) ? r.month : r.month.to_s.capitalize }
    crop_types = yields.pluck(:crop_type).compact.uniq
    labels_ordenadas = grouped.keys.sort_by { |m| MESES_PT.index(m) || 99 }

    @crop_data = {
      labels: labels_ordenadas,
      datasets: crop_types.map do |type|
        {
          label: type.to_s.capitalize,
          data: labels_ordenadas.map { |m| grouped[m].select { |r| r.crop_type == type }.sum(&:amount) },
          backgroundColor: "##{SecureRandom.hex(3)}"
        }
      end
    }

    # 🌡️ Temperatura média diária e mensal (SOLO)
    @daily_temperature = avg_by_hour(@soil_data, :measured_at) { |rec| rec.temperature }
    @monthly_temperature = avg_by_month(@soil_data, :measured_at) { |rec| rec.temperature }

    # 💧 Humidade do Solo
    @daily_moisture = avg_by_hour(@soil_data, :measured_at) { |rec| rec.moisture }
    @monthly_moisture = avg_by_month(@soil_data, :measured_at) { |rec| rec.moisture }

    # 💰 Despesas por Categoria
    @expense_distribution = @financial_data.group(:expense_category).sum(:expenses)

    # 💦 Gasto com Irrigação (mensal)
    @irrigation_expenses_by_month = @financial_data
      .where(expense_category: "irrigação")
      .group_by { |f| f.recorded_at.strftime("%b") }
      .transform_values { |recs| recs.sum(&:expenses) }

    # 🧪 Outros recursos (fertilizante, energia, etc.)
    @non_irrigation_expenses = @financial_data
      .where.not(expense_category: "irrigação")
      .group(:expense_category).sum(:expenses)

    # 💧 Eficiência da Irrigação (€/tonelada)
    @crop_yield_by_month = yields.group_by(&:month).transform_values { |recs| recs.sum(&:amount) }
    @irrigation_efficiency_by_month = {}
    @crop_yield_by_month.each do |month, total_yield|
      irrigation_expense = @irrigation_expenses_by_month[month] || 0
      eff = total_yield.to_f.positive? ? (irrigation_expense / total_yield.to_f).round(2) : 0
      @irrigation_efficiency_by_month[month] = eff
    end

    # 📊 Comparação entre campos
    @field_comparison_data = Field.all.map do |field|
      {
        field_name: field.name,
        production: field.crop_yields.sum(:amount).to_f.round(2),
        total_expenses: field.financials.sum(:expenses).to_f.round(2),
        irrigation_expenses: field.financials.where(expense_category: "irrigação").sum(:expenses).to_f.round(2)
      }
    end

    # 📈 Produção acumulada ao longo da época
    @cumulative_production_by_month = {}
    monthly_production = yields.group_by(&:month).transform_values { |recs| recs.sum(&:amount).to_f }
    acc = 0.0
    MESES_PT.each do |mes|
      acc += (monthly_production[mes] || 0.0)
      @cumulative_production_by_month[mes] = acc.round(2)
    end

    # 💰 Rentabilidade por Cultura (estimativa)
    @profit_by_crop_type = {}
    crop_types.each do |type|
      production_amount = yields.where(crop_type: type).sum(:amount).to_f
      estimated_revenue = production_amount * 200 # <— ajusta à tua realidade
      total_expenses    = @financial_data.sum(:expenses).to_f
      expenses_per_crop = crop_types.size.positive? ? (total_expenses / crop_types.size) : 0
      profit = estimated_revenue - expenses_per_crop
      @profit_by_crop_type[type.to_s.capitalize] = profit.round(2)
    end

    # 📏 Custos por hectare (€/ha)
    @cost_per_hectare_by_field = {}
    Field.find_each do |field|
      total_expenses = field.financials.sum(:expenses).to_f
      area_ha = field.area.to_f.positive? ? field.area.to_f : 1.0
      @cost_per_hectare_by_field[field.name] = (total_expenses / area_ha).round(2)
    end

    # ✅ Sensores agregados (ambiente geral)
    @daily_light_intensity = avg_by_hour(@sensor_readings, :read_at) { |r| r.light_intensity }
    @daily_wind_speed      = avg_by_hour(@sensor_readings, :read_at) { |r| r.wind_speed }
    @daily_wind_direction  = avg_by_hour(@sensor_readings, :read_at) { |r| r.wind_direction }
    @daily_air_temperature = avg_by_hour(@sensor_readings, :read_at) { |r| r.air_temperature }
    @daily_air_humidity    = avg_by_hour(@sensor_readings, :read_at) { |r| r.air_humidity }
    @daily_soil_ph         = avg_by_hour(@sensor_readings, :read_at) { |r| r.soil_ph }
    @daily_soil_ec         = avg_by_hour(@sensor_readings, :read_at) { |r| r.soil_ec }
    @daily_soil_nitrogen   = avg_by_hour(@sensor_readings, :read_at) { |r| r.soil_nitrogen }
    @daily_soil_potassium  = avg_by_hour(@sensor_readings, :read_at) { |r| r.soil_potassium }
    @daily_soil_phosphorus = avg_by_hour(@sensor_readings, :read_at) { |r| r.soil_phosphorus }

    @latest_uptime      = @sensor_readings.order(read_at: :desc).limit(1).pluck(:uptime).first
    @latest_error_count = @sensor_readings.order(read_at: :desc).limit(1).pluck(:error_count).first
  end

  # =====================
  # Aquacultura (Mar)
  # =====================
  def build_aquaculture_sea_datasets!
    readings = @sensor_readings
    readings = readings.where(environment: "sea") if readings.klass.column_names.include?("environment") rescue readings

    ordered = readings.order(:read_at)
    @sea_labels      = ordered.pluck(:read_at).map { |t| t.strftime("%d/%m %Hh") }
    @sea_water_temp  = ordered.pluck(:water_temperature).compact
    @sea_salinity    = ordered.pluck(:salinity).compact if column?(readings, :salinity)
    @sea_ph          = ordered.pluck(:ph).compact       if column?(readings, :ph)
    @sea_turbidity   = ordered.pluck(:turbidity).compact if column?(readings, :turbidity)

    # Biomassa & mortalidade (se existirem colunas; senão ficam vazios)
    @sea_biomass_growth = ordered.pluck(:biomass_kg).compact if column?(readings, :biomass_kg)
    @sea_mortality      = ordered.pluck(:mortality_rate).compact if column?(readings, :mortality_rate)

    # Operações
    @sea_uptime       = ordered.limit(1).pluck(:uptime).first
    @sea_alerts       = ordered.limit(1).pluck(:alerts).first if column?(readings, :alerts)
    @sea_energy_costs = monthly_sum(@financial_data, "energia")
  end

  # =====================
  # Aquacultura (Tanques)
  # =====================
  def build_aquaculture_tank_datasets!
    readings = @sensor_readings
    readings = readings.where(environment: "tank") if readings.klass.column_names.include?("environment") rescue readings

    ordered = readings.order(:read_at)
    @tank_labels  = ordered.pluck(:read_at).map { |t| t.strftime("%d/%m %Hh") }
    @tank_do      = ordered.pluck(:dissolved_oxygen).compact if column?(readings, :dissolved_oxygen)
    @tank_ammonia = ordered.pluck(:ammonia).compact          if column?(readings, :ammonia)
    @tank_temp    = ordered.pluck(:water_temperature).compact if column?(readings, :water_temperature)
    @tank_ph      = ordered.pluck(:ph).compact                if column?(readings, :ph)

    @tank_biomass_growth = ordered.pluck(:biomass_kg).compact if column?(readings, :biomass_kg)
    @tank_fcr            = ordered.pluck(:fcr).compact        if column?(readings, :fcr)

    @tank_uptime       = ordered.limit(1).pluck(:uptime).first
    @tank_errors       = ordered.limit(1).pluck(:error_count).first
    @tank_energy_costs = monthly_sum(@financial_data, "energia")
  end

  # -------------------------------------------------------------------
  # Serializadores JSON (um por domínio)
  # -------------------------------------------------------------------
  def json_agriculture
    total_producao   = (@cumulative_production_by_month || {}).values.compact.map(&:to_f).sum
    hum_mes_vals     = (@monthly_moisture || {}).values
    eficiencia_pct   = hum_mes_vals.present? ? (hum_mes_vals.sum.to_f / hum_mes_vals.size).round(1) : nil
    custos_total     = @financial_data&.sum(:expenses).to_f
    gauge_score      = begin
                         v = (@irrigation_efficiency_by_month || {}).values.compact.last
                         v ? [[(100 - (v.to_f * 3)).round, 5].max, 100].min : nil
                       end

    {
      domain: "agriculture",
      kpis: {
        total: total_producao.round(0),
        efficiency_pct: eficiencia_pct,
        costs_eur: custos_total.round(2),
        water_quality_pct: nil
      },
      charts: {
        line: {
          categories: MESES_PT,
          series: [{ name: "Produção", data: MESES_PT.map { |m| (@cumulative_production_by_month || {})[m].to_f } }]
        },
        bars: {
          categories: (@expense_distribution || {}).keys,
          series: [{ name: "Despesas", data: (@expense_distribution || {}).values.map(&:to_f) }]
        },
        donut: {
          labels: (@non_irrigation_expenses || {}).keys,
          data:   (@non_irrigation_expenses || {}).values.map(&:to_f)
        },
        gauge: { value: gauge_score }
      },
      updated_at: Time.current
    }
  end

  def json_sea
    qualidade_pct = water_quality_score(
      ph: (@sea_ph || []).last,
      turbidity: (@sea_turbidity || []).last
    )
    custos_energia = sum_numeric_hash(@sea_energy_costs)

    {
      domain: "aquaculture_sea",
      kpis: {
        total: (@sea_biomass_growth || []).compact.map(&:to_f).sum.round(0),
        efficiency_pct: nil,
        costs_eur: custos_energia.round(2),
        water_quality_pct: qualidade_pct
      },
      charts: {
        line: {
          categories: (@sea_labels || []),
          series: [{ name: "Temp. Água (°C)", data: (@sea_water_temp || []).map(&:to_f) }]
        },
        bars: {
          # substitui por dados reais de captura por zona quando tiveres
          categories: %w[Zona\ A Zona\ B Zona\ C Zona\ D],
          series: [{ name: "Captura", data: (@sea_salinity || [1700, 2200, 1400, 1900]).first(4).map(&:to_f) }]
        },
        donut: {
          labels: %w[Atum Sardinha Bacalhau Outros],
          data:   [40, 35, 15, 10]
        },
        gauge: { value: (@sea_biomass_growth.present? ? 84 : nil) }
      },
      updated_at: Time.current
    }
  end

  def json_tank
    qualidade_pct = water_quality_score(ph: (@tank_ph || []).last)
    custos_energia = sum_numeric_hash(@tank_energy_costs)
    fcr_last       = (@tank_fcr || []).last
    gauge_score    = fcr_last ? (100 - (fcr_last.to_f * 10)).round : 80

    {
      domain: "aquaculture_tank",
      kpis: {
        total: (@tank_biomass_growth || []).compact.map(&:to_f).sum.round(0),
        efficiency_pct: nil,
        costs_eur: custos_energia.round(2),
        water_quality_pct: qualidade_pct
      },
      charts: {
        line: {
          categories: (@tank_labels || []),
          series: [{ name: "Temp. Água (°C)", data: (@tank_temp || []).map(&:to_f) }]
        },
        bars: {
          categories: %w[Tanque\ 1 Tanque\ 2 Tanque\ 3 Tanque\ 4],
          series: [{ name: "Produção", data: (@tank_biomass_growth || [800, 950, 700, 860]).first(4).map(&:to_f) }]
        },
        donut: {
          labels: %w[Dourada Robalo Tilápia Outros],
          data:   [30, 40, 20, 10]
        },
        gauge: { value: gauge_score }
      },
      updated_at: Time.current
    }
  end

  # -------------------------------------------------------------------
  # Helpers genéricos (auto-contidos neste controller)
  # -------------------------------------------------------------------
  def safe_parse_date(str)
    return nil if str.blank?
    Date.parse(str) rescue nil
  end

  def avg_by_hour(relation, time_column)
    relation.group_by { |r| r.public_send(time_column).strftime("%Y-%m-%d %H:00") }
            .transform_values do |records|
              vals = records.map { |rec| yield(rec) }.compact
              vals.any? ? (vals.sum.to_f / vals.size) : nil
            end.compact
  end

  def avg_by_month(relation, time_column)
    relation.group_by { |r| r.public_send(time_column).strftime("%b") }
            .transform_values do |records|
              vals = records.map { |rec| yield(rec) }.compact
              vals.any? ? (vals.sum.to_f / vals.size) : nil
            end.compact
  end

  def monthly_sum(financials, category)
    financials.where(expense_category: category)
              .group_by { |f| f.recorded_at.strftime("%b") }
              .transform_values { |recs| recs.sum(&:expenses).to_f }
  end

  # evita rebentar se a coluna não existir nesta instância
  def column?(relation, name)
    relation.klass.column_names.include?(name.to_s)
  rescue
    false
  end

  def sum_numeric_hash(h)
    h.to_h.values.compact.map(&:to_f).sum
  end

  # Score simples 0–100 a partir de pH (~7.5 ideal) e turbidez (baixo é melhor)
  def water_quality_score(ph: nil, turbidity: nil)
    return nil if ph.nil? && turbidity.nil?
    score_ph =
      if ph.nil? then 50
      else
        diff = (ph.to_f - 7.5).abs
        [[100 - diff * 18.0, 0].max, 100].min
      end
    score_turb =
      if turbidity.nil? then 70
      else
        case turbidity.to_f
        when 0..5   then 95
        when 5..10  then 85
        when 10..20 then 70
        else 50
        end
      end
    ((score_ph + score_turb) / 2.0).round
  end
end
