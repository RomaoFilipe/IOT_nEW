class AnalyticsController < ApplicationController
  MESES_PT = %w[Jan Fev Mar Abr Mai Jun Jul Ago Set Out Nov Dez]

  def index
    @fields = Field.all
    @available_cultures = CropYield.distinct.pluck(:crop_type).compact.sort

    # Filtros recebidos
    selected_culture = params[:culture]

    # Filtro de data início
    if params[:start_date].present?
      begin
        start_date = Date.parse(params[:start_date])
      rescue ArgumentError
        start_date = nil
      end
    else
      start_date = nil
    end

    # Filtro de data fim
    if params[:end_date].present?
      begin
        end_date = Date.parse(params[:end_date])
      rescue ArgumentError
        end_date = nil
      end
    else
      end_date = nil
    end

    # Dados Base
    if params[:field_id].present?
      @selected_field = Field.find(params[:field_id])
      yields = @selected_field.crop_yields
      @soil_data = @selected_field.soil_readings
      @financial_data = @selected_field.financials
    else
      yields = CropYield.all
      @soil_data = SoilReading.all
      @financial_data = Financial.all
    end

    # Aplicar filtros
    yields = yields.where(crop_type: selected_culture) if selected_culture.present?

    if start_date.present?
      yields = yields.where("created_at >= ?", start_date)
      @soil_data = @soil_data.where("measured_at >= ?", start_date)
      @financial_data = @financial_data.where("recorded_at >= ?", start_date)
    end

    if end_date.present?
      yields = yields.where("created_at <= ?", end_date)
      @soil_data = @soil_data.where("measured_at <= ?", end_date)
      @financial_data = @financial_data.where("recorded_at <= ?", end_date)
    end

    # 📊 Produção por Cultura e Mês
    grouped = yields.group_by { |r| MESES_PT.include?(r.month) ? r.month : r.month.capitalize }
    crop_types = yields.pluck(:crop_type).compact.uniq
    labels_ordenadas = grouped.keys.sort_by { |m| MESES_PT.index(m) || 99 }

    @crop_data = {
      labels: labels_ordenadas,
      datasets: crop_types.map do |type|
        {
          label: type.capitalize,
          data: labels_ordenadas.map { |m| grouped[m].select { |r| r.crop_type == type }.sum(&:amount) },
          backgroundColor: "##{SecureRandom.hex(3)}"
        }
      end
    }

    # 🌡️ Temperatura média diária e mensal
    @daily_temperature = @soil_data.group_by { |r| r.measured_at.strftime("%Y-%m-%d %H:00") }
.transform_values do |records|
      records.map(&:temperature).compact.sum / records.size.to_f
    end

    @monthly_temperature = @soil_data.group_by { |r| r.measured_at.strftime("%b") }.transform_values do |records|
      records.map(&:temperature).compact.sum / records.size.to_f
    end

    # 💧 Humidade do Solo
    @daily_moisture = @soil_data.group_by { |r| r.measured_at.strftime("%Y-%m-%d %H:00") }
.transform_values do |v|
      v.sum(&:moisture).to_f / v.size
    end

    @monthly_moisture = @soil_data.group_by { |r| r.measured_at.strftime("%b") }.transform_values do |v|
      v.sum(&:moisture).to_f / v.size
    end

    # 💰 Despesas por Categoria
    @expense_distribution = @financial_data.group(:expense_category).sum(:expenses)

    # 💦 Gasto com Irrigação (mensal)
    @irrigation_expenses_by_month = @financial_data
      .where(expense_category: "irrigação")
      .group_by { |f| f.recorded_at.strftime("%b") }
      .transform_values { |records| records.sum(&:expenses) }

    # 🧪 Outros recursos (fertilizante, energia, etc.)
    @non_irrigation_expenses = @financial_data
      .where.not(expense_category: 'irrigação')
      .group(:expense_category)
      .sum(:expenses)

    # 💧 Eficiência da Irrigação (€/tonelada)
    @crop_yield_by_month = yields.group_by { |r| r.month }.transform_values { |records| records.sum(&:amount) }

    @irrigation_efficiency_by_month = {}
    @crop_yield_by_month.each do |month, total_yield|
      irrigation_expense = @irrigation_expenses_by_month[month] || 0
      efficiency = total_yield > 0 ? (irrigation_expense / total_yield.to_f).round(2) : 0
      @irrigation_efficiency_by_month[month] = efficiency
    end

    # 📊 Comparação entre campos
    @field_comparison_data = Field.all.map do |field|
      field_yield = field.crop_yields.sum(:amount)
      field_total_expenses = field.financials.sum(:expenses)
      field_irrigation_expenses = field.financials.where(expense_category: 'irrigação').sum(:expenses)

      {
        field_name: field.name,
        production: field_yield.round(2),
        total_expenses: field_total_expenses.round(2),
        irrigation_expenses: field_irrigation_expenses.round(2)
      }
    end

    # 📈 Produção acumulada ao longo da época
    @cumulative_production_by_month = {}
    monthly_production = yields.group_by { |r| r.month }.transform_values { |records| records.sum(&:amount) }

    accumulated = 0.0
    MESES_PT.each do |mes|
      month_value = monthly_production[mes] || 0
      accumulated += month_value
      @cumulative_production_by_month[mes] = accumulated.round(2)
    end

    # 💰 Rentabilidade por Cultura (Lucro = Receita - Despesas)
    @profit_by_crop_type = {}
    crop_types.each do |type|
      production_amount = yields.where(crop_type: type).sum(:amount)
      estimated_revenue = production_amount * 200
      total_expenses = @financial_data.sum(:expenses)
      expenses_per_crop = total_expenses / crop_types.size
      profit = estimated_revenue - expenses_per_crop

      @profit_by_crop_type[type.capitalize] = profit.round(2)
    end

    # 📏 Custos por hectare (€/ha)
    @cost_per_hectare_by_field = {}
    Field.all.each do |field|
      total_expenses = field.financials.sum(:expenses)
      area_ha = field.area > 0 ? field.area : 1
      cost_per_ha = total_expenses / area_ha
      @cost_per_hectare_by_field[field.name] = cost_per_ha.round(2)
    end
    # ✅ 🚀 CAMPOS NOVOS — para os gráficos novos (SensorReadings)
    @daily_light_intensity = @soil_data.group_by { |r| r.measured_at.strftime("%Y-%m-%d %H:00") }
.transform_values do |records|
      records.map(&:light_intensity).compact.sum / records.size.to_f
    end

    @daily_wind_speed = @soil_data.group_by { |r| r.measured_at.strftime("%Y-%m-%d %H:00") }
.transform_values do |records|
      records.map(&:wind_speed).compact.sum / records.size.to_f
    end

    @daily_wind_direction = @soil_data.group_by { |r| r.measured_at.strftime("%Y-%m-%d %H:00") }
.transform_values do |records|
      records.map(&:wind_direction).compact.sum / records.size.to_f
    end

    @daily_air_temperature = @soil_data.group_by { |r| r.measured_at.strftime("%Y-%m-%d %H:00") }
.transform_values do |records|
      records.map(&:air_temperature).compact.sum / records.size.to_f
    end

    @daily_air_humidity = @soil_data.group_by { |r| r.measured_at.strftime("%Y-%m-%d %H:00") }
.transform_values do |records|
      records.map(&:air_humidity).compact.sum / records.size.to_f
    end

    @daily_soil_ph = @soil_data.group_by { |r| r.measured_at.strftime("%Y-%m-%d %H:00") }
.transform_values do |records|
      records.map(&:soil_ph).compact.sum / records.size.to_f
    end

    @daily_soil_ec = @soil_data.group_by { |r| r.measured_at.strftime("%Y-%m-%d %H:00") }
.transform_values do |records|
      records.map(&:soil_ec).compact.sum / records.size.to_f
    end

    @daily_soil_nitrogen = @soil_data.group_by { |r| r.measured_at.strftime("%Y-%m-%d %H:00") }
.transform_values do |records|
      records.map(&:soil_nitrogen).compact.sum / records.size.to_f
    end

    @daily_soil_potassium = @soil_data.group_by { |r| r.measured_at.strftime("%Y-%m-%d %H:00") }
.transform_values do |records|
      records.map(&:soil_potassium).compact.sum / records.size.to_f
    end

    @daily_soil_phosphorus = @soil_data.group_by { |r| r.measured_at.strftime("%Y-%m-%d %H:00") }
.transform_values do |records|
      records.map(&:soil_phosphorus).compact.sum / records.size.to_f
    end

    @latest_uptime = @soil_data.order(measured_at: :desc).limit(1).pluck(:uptime).first

    @latest_error_count = @soil_data.order(measured_at: :desc).limit(1).pluck(:error_count).first
  end
end
