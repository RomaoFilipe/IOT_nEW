class AnalyticsController < ApplicationController
  MESES_PT = %w[Jan Fev Mar Abr Mai Jun Jul Ago Set Out Nov Dez]

  def index
    @fields = Field.all

    if params[:field_id].present?
      @selected_field = Field.find(params[:field_id])
      yields = @selected_field.crop_yields
    else
      yields = CropYield.all
    end

    # Gerar dados para gráfico: produção por cultura e mês
    @crop_data = { labels: [], datasets: [] }

    # Agrupar por mês com normalização
    grouped = yields.group_by do |record|
      MESES_PT.include?(record.month) ? record.month : record.month.capitalize
    end

    crop_types = yields.pluck(:crop_type).compact.uniq

    # Ordenar os labels dos meses pela ordem portuguesa
    @crop_data[:labels] = grouped.keys.sort_by { |mes| MESES_PT.index(mes) || 99 }

    crop_types.each do |type|
      data = @crop_data[:labels].map do |mes|
        grouped[mes].select { |r| r.crop_type == type }.sum { |r| r.amount.to_f }
      end

      @crop_data[:datasets] << {
        label: type.capitalize,
        data: data,
        backgroundColor: "##{SecureRandom.hex(3)}"
      }
    end

    # Dados de solo e finanças (opcional por campo)
    @soil_data = params[:field_id] ? @selected_field.soil_readings : SoilReading.all
    @financial_data = params[:field_id] ? @selected_field.financials : Financial.all
  end
end
