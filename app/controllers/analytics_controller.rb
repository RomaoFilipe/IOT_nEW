class AnalyticsController < ApplicationController

  require 'csv'

  MESES_PT = %w[Jan Fev Mar Abr Mai Jun Jul Ago Set Out Nov Dez]

  def index
    @fields = Field.all
    @available_cultures = CropYield.distinct.pluck(:crop_type).compact.sort

    # Filtros recebidos
    selected_culture = params[:culture]
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]) rescue nil : nil
    end_date = params[:end_date].present? ? Date.parse(params[:end_date]) rescue nil : nil

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
      }
    }

    # 🌡️ Temperatura média diária e mensal
    @daily_temperature = @soil_data.group_by { |r| r.measured_at.to_date }.transform_values do |records|
      records.map(&:temperature).compact.sum / records.size.to_f
    end

    @monthly_temperature = @soil_data.group_by { |r| r.measured_at.strftime("%b") }.transform_values do |records|
      records.map(&:temperature).compact.sum / records.size.to_f
    end

    # 💧 Humidade do Solo
    @daily_moisture = @soil_data.group_by { |r| r.measured_at.to_date }.transform_values do |v|
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
  end

  def export_csv
    # Gerar CSV da Produção por Cultura (exemplo inicial)
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ["Cultura", "Mês", "Quantidade (ton)"]
  
      # Recalcular com os filtros atuais
      yields = if params[:field_id].present?
        Field.find(params[:field_id]).crop_yields
      else
        CropYield.all
      end
  
      if params[:culture].present?
        yields = yields.where(crop_type: params[:culture])
      end
  
      start_date = params[:start_date].present? ? Date.parse(params[:start_date]) rescue nil : nil
      end_date = params[:end_date].present? ? Date.parse(params[:end_date]) rescue nil : nil
  
      if start_date.present?
        yields = yields.where("created_at >= ?", start_date)
      end
      if end_date.present?
        yields = yields.where("created_at <= ?", end_date)
      end
  
      # Gerar linhas do CSV
      yields.group_by { |r| [r.crop_type, r.month] }.each do |(crop, month), records|
        total_amount = records.sum(&:amount)
        csv << [crop, month, total_amount.round(2)]
      end
    end
  
    # Enviar CSV para download
    send_data csv_data, filename: "producao_culturas_#{Date.today}.csv"
  end


  def export_field_comparison_csv
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ["Campo", "Produção (ton)", "Total de despesas (€)", "Gasto com irrigação (€)"]
  
      Field.all.each do |field|
        field_yield = field.crop_yields.sum(:amount)
        field_total_expenses = field.financials.sum(:expenses)
        field_irrigation_expenses = field.financials.where(expense_category: 'irrigação').sum(:expenses)
  
        csv << [
          field.name,
          field_yield.round(2),
          field_total_expenses.round(2),
          field_irrigation_expenses.round(2)
        ]
      end
    end
  
    send_data csv_data, filename: "comparacao_campos_#{Date.today}.csv"
  end
  

  def export_irrigation_efficiency_csv
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ["Mês", "Eficiência (€/tonelada)"]
  
      # Como a eficiência já é calculada no index, vamos recalcular aqui novamente com os filtros
      yields = if params[:field_id].present?
        Field.find(params[:field_id]).crop_yields
      else
        CropYield.all
      end
  
      if params[:culture].present?
        yields = yields.where(crop_type: params[:culture])
      end
  
      start_date = params[:start_date].present? ? Date.parse(params[:start_date]) rescue nil : nil
      end_date = params[:end_date].present? ? Date.parse(params[:end_date]) rescue nil : nil
  
      if start_date.present?
        yields = yields.where("created_at >= ?", start_date)
      end
      if end_date.present?
        yields = yields.where("created_at <= ?", end_date)
      end
  
      # Recalcular despesas de irrigação
      financial_data = if params[:field_id].present?
        Field.find(params[:field_id]).financials
      else
        Financial.all
      end
  
      if start_date.present?
        financial_data = financial_data.where("recorded_at >= ?", start_date)
      end
      if end_date.present?
        financial_data = financial_data.where("recorded_at <= ?", end_date)
      end
  
      irrigation_expenses_by_month = financial_data
        .where(expense_category: "irrigação")
        .group_by { |f| f.recorded_at.strftime("%b") }
        .transform_values { |records| records.sum(&:expenses) }
  
      crop_yield_by_month = yields.group_by { |r| r.month }.transform_values { |records| records.sum(&:amount) }
  
      # Calcular eficiência
      MESES_PT.each do |mes|
        total_yield = crop_yield_by_month[mes] || 0
        irrigation_expense = irrigation_expenses_by_month[mes] || 0
        efficiency = total_yield > 0 ? (irrigation_expense / total_yield.to_f).round(2) : 0
  
        csv << [mes, efficiency]
      end
    end
  
    send_data csv_data, filename: "eficiencia_irrigacao_#{Date.today}.csv"
  end
  


end
