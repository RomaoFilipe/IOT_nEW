class AnalyticsController < ApplicationController
  MESES_PT = %w[Jan Fev Mar Abr Mai Jun Jul Ago Set Out Nov Dez]

  def index
    @fields = Field.all

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
      .group_by { |f| f.recorded_at.strftime("%b %Y") }
      .transform_values { |records| records.sum(&:expenses) }

    # 🧪 Outros recursos (fertilizante, energia, etc.)
    @non_irrigation_expenses = @financial_data
    .where.not(expense_category: 'irrigação')
    .group(:expense_category)
    .sum(:expenses)
  end
end
