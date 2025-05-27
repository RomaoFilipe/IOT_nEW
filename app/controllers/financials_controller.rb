class FinancialsController < ApplicationController
  def create
    @financial = Financial.new(financial_params)
    if @financial.save
      redirect_back fallback_location: fields_path, notice: "Registo financeiro adicionado com sucesso."
    else
      redirect_back fallback_location: fields_path, alert: "Erro ao adicionar registo financeiro."
    end
  end

  private

  def financial_params
    params.require(:financial).permit(:field_id, :revenue, :expenses, :profit, :recorded_at)
  end
end
