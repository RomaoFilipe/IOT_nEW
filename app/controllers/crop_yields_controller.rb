# app/controllers/crop_yields_controller.rb
class CropYieldsController < ApplicationController
  before_action :authenticate_user!

  MESES_PT = %w[Jan Fev Mar Abr Mai Jun Jul Ago Set Out Nov Dez].freeze

  # Recebe arrays do modal e cria vários registos
  def create
    cy         = params.fetch(:crop_yield, {})
    field_id   = cy[:field_id]
    crop_types = Array(cy[:crop_type])
    amounts    = Array(cy[:amount])
    months     = Array(cy[:month])

    created = 0

    crop_types.each_with_index do |type, i|
      next if type.blank?

      amt = amounts[i].to_f
      next if amt <= 0

      mes = months[i].presence
      mes = mes.in?(MESES_PT) ? mes : nil

      attrs = {
        field_id:  field_id,
        crop_type: type,
        amount:    amt
      }

      # Se o modelo tiver measured_at, gravamos o último dia do mês selecionado para ajudar nos gráficos diários/mensais
      if CropYield.column_names.include?("measured_at")
        measured_at =
          if mes
            month_index = MESES_PT.index(mes) + 1
            Date.new(Time.zone.today.year, month_index, 1).end_of_month
          else
            Time.zone.today
          end
        attrs[:measured_at] = measured_at
      else
        attrs[:month] = mes # fallback textual
      end

      CropYield.create!(attrs)
      created += 1
    end

    redirect_to analytics_path, notice: "#{created} registo(s) guardado(s)."
  rescue => e
    redirect_to analytics_path, alert: "Erro a guardar: #{e.message}"
  end
end
