# app/controllers/admin/production_facts_controller.rb
class Admin::ProductionFactsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_fact, only: %i[edit update destroy]

  def index
    @facts = current_company.production_facts.order(period_start: :desc)
  end

  def new
    @fact = current_company.production_facts.new
  end

  def create
    @fact = current_company.production_facts.new(fact_params)
    if @fact.save
      redirect_to admin_production_facts_path, notice: "Guardado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @fact.update(fact_params)
      redirect_to admin_production_facts_path, notice: "Atualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @fact.destroy
    redirect_to admin_production_facts_path, notice: "Removido."
  end

  private
  def set_fact
    @fact = current_company.production_facts.find(params[:id])
  end

  def fact_params
    params.require(:production_fact).permit(:period_start, :period_end,
      :target_output_kg, :realized_output_kg, :costs_eur, :efficiency_pct, :notes)
  end
end
