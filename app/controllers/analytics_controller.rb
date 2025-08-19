# app/controllers/analytics_controller.rb
class AnalyticsController < ApplicationController
  MESES_PT = %w[Jan Fev Mar Abr Mai Jun Jul Ago Set Out Nov Dez].freeze

  # -------------------------------------------------------------------
  # UI principal (server-render)
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

      # NOVO: leituras de aquacultura
      @aq_readings     = @selected_field ? AquacultureReading.where(field_id: @selected_field.id) : AquacultureReading.none
    else
      yields_scope     = CropYield.all
      @soil_data       = SoilReading.all
      @financial_data  = Financial.all
      @aq_readings     = AquacultureReading.all
    end

    # Cultura (apenas faz sentido para Agricultura)
    yields_scope = yields_scope.where(crop_type: @selected_culture) if @selected_culture.present?

    # Datas
    if @start_date
      yields_scope     = yields_scope.where("created_at >= ?", @start_date)
      @soil_data       = @soil_data.where("measured_at >= ?", @start_date)
      @financial_data  = @financial_data.where("recorded_at >= ?", @start_date)
      @aq_readings     = @aq_readings.where("measured_at >= ?", @start_date)
    end
    if @end_date
      yields_scope     = yields_scope.where("created_at <= ?", @end_date)
      @soil_data       = @soil_data.where("measured_at <= ?", @end_date)
      @financial_data  = @financial_data.where("recorded_at <= ?", @end_date)
      @aq_readings     = @aq_readings.where("measured_at <= ?", @end_date)
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
  # Endpoint JSON (para AJAX/auto-refresh)
  # GET /analytics/data.json
  # -------------------------------------------------------------------
  def data
    # Preparação igual à index
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
      @aq_readings     = @selected_field ? AquacultureReading.where(field_id: @selected_field.id) : AquacultureReading.none
    else
      yields_scope     = CropYield.all
      @soil_data       = SoilReading.all
      @financial_data  = Financial.all
      @aq_readings     = AquacultureReading.all
    end

    yields_scope = yields_scope.where(crop_type: @selected_culture) if @selected_culture.present?

    if @start_date
      yields_scope     = yields_scope.where("created_at >= ?", @start_date)
      @soil_data       = @soil_data.where("measured_at >= ?", @start_date)
      @financial_data  = @financial_data.where("recorded_at >= ?", @start_date)
      @aq_readings     = @aq_readings.where("measured_at >= ?", @start_date)
    end
    if @end_date
      yields_scope     = yields_scope.where("created_at <= ?", @end_date)
      @soil_data       = @soil_data.where("measured_at <= ?", @end_date)
      @financial_data  = @financial_data.where("recorded_at <= ?", @end_date)
      @aq_readings     = @aq_readings.where("measured_at <= ?", @end_date)
    end

    # Construção e serialização
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
  # Agricultura (igual ao que já tinhas)
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
    @daily_temperature   = avg_by_hour(@soil_data, :measured_at) { |rec| rec.temperature }
    @monthly_temperature = avg_by_month(@soil_data, :measured_at) { |rec| rec.temperature }

    # 💧 Humidade do Solo
    @daily_moisture   = avg_by_hour(@soil_data, :measured_at) { |rec| rec.moisture }
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
      estimated_revenue = production_amount * 200 # ajustar à realidade
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
    @latest_uptime      = nil
    @latest_error_count = nil
  end

  # =====================
  # Aquacultura (Mar) — usa AquacultureReading
  # =====================
  def build_aquaculture_sea_datasets!
    readings = @aq_readings
    ordered  = readings.order(:measured_at)

    @sea_labels      = ordered.pluck(:measured_at).map { |t| t.strftime("%d/%m %Hh") }
    @sea_water_temp  = ordered.pluck(:temperature).compact
    @sea_salinity    = has_column?(AquacultureReading, :salinity)      ? ordered.pluck(:salinity).compact       : []
    @sea_ph          = has_column?(AquacultureReading, :ph)            ? ordered.pluck(:ph).compact             : []
    @sea_oxygen      = has_column?(AquacultureReading, :oxygen_level)  ? ordered.pluck(:oxygen_level).compact   : []

    # Métricas que não tens (mantemos vazias para UI não rebentar)
    @sea_turbidity      = []
    @sea_biomass_growth = []
    @sea_mortality      = []

    # Operações (não existem em AquacultureReading; podes ligar a outra fonte se tiveres)
    @sea_uptime       = nil
    @sea_alerts       = nil
    @sea_energy_costs = monthly_sum(@financial_data, "energia")
  end

  # =====================
  # Aquacultura (Tanques) — reutiliza AquacultureReading
  # =====================
  def build_aquaculture_tank_datasets!
    readings = @aq_readings
    ordered  = readings.order(:measured_at)

    @tank_labels  = ordered.pluck(:measured_at).map { |t| t.strftime("%d/%m %Hh") }
    @tank_temp    = ordered.pluck(:temperature).compact
    @tank_ph      = has_column?(AquacultureReading, :ph)            ? ordered.pluck(:ph).compact             : []
    @tank_do      = has_column?(AquacultureReading, :oxygen_level)  ? ordered.pluck(:oxygen_level).compact   : []
    @tank_ammonia = [] # não tens amónia
    @tank_biomass_growth = [] # não tens biomassa
    @tank_fcr            = [] # não tens fcr

    @tank_uptime       = nil
    @tank_errors       = nil
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

    bars_categories = %w[Zona\ A Zona\ B Zona\ C Zona\ D]
    bars_series     = Array.new(bars_categories.size, 0) # sem zonas disponíveis

    {
      domain: "aquaculture_sea",
      kpis: {
        total: 0, # sem biomassa/captura -> 0 (ajusta quando tiveres)
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
          categories: bars_categories,
          series: [{ name: "Captura", data: bars_series }]
        },
        donut: {
          labels: %w[Espécie\ A Espécie\ B Espécie\ C Outros],
          data:   [40, 35, 15, 10]
        },
        gauge: { value: qualidade_pct } # usa qualidade como gauge (até existirem métricas de frota)
      },
      updated_at: Time.current
    }
  end

  def json_tank
    qualidade_pct = water_quality_score(ph: (@tank_ph || []).last)
    custos_energia = sum_numeric_hash(@tank_energy_costs)

    bars_categories = %w[Tanque\ 1 Tanque\ 2 Tanque\ 3 Tanque\ 4]
    bars_series     = Array.new(bars_categories.size, 0)

    {
      domain: "aquaculture_tank",
      kpis: {
        total: 0,
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
          categories: bars_categories,
          series: [{ name: "Produção", data: bars_series }]
        },
        donut: {
          labels: %w[Dourada Robalo Tilápia Outros],
          data:   [30, 40, 20, 10]
        },
        gauge: { value: qualidade_pct }
      },
      updated_at: Time.current
    }
  end

  # -------------------------------------------------------------------
  # Helpers genéricos
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

  # testa colunas numa classe ActiveRecord (ex.: AquacultureReading)
  def has_column?(klass, name)
    klass.column_names.include?(name.to_s)
  rescue
    false
  end

  # evita rebentar se a coluna não existir numa relation
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
      if turbidity.nil? then 80 # se não tens turbidez, assume aceitável
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
