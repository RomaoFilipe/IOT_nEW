# app/controllers/analytics_controller.rb
class AnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_company!
  before_action :set_effective_kind!

  # GET /analytics
  def index
    # A tua view já faz fetch a /analytics/data.json
    respond_to { |f| f.html }
  end

  # GET /analytics/data(.json)?period=7d|30d|quarter|year&production_kind=...
  def data
    period  = safe_period(params[:period])
    payload = Analytics::BuildData.call(
      company: @company,
      kind:    @effective_kind,
      period:  period
    )

    response.set_header("Cache-Control", "max-age=10, public")
    render json: payload, status: :ok
  rescue StandardError => e
    Rails.logger.error("[AnalyticsController#data] #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    render json: { error: "Falha ao gerar analytics." }, status: :unprocessable_entity
  end

  # GET /analytics/export(.csv|.pdf)?period=...&production_kind=...
  def export
    period  = safe_period(params[:period])
    payload = Analytics::BuildData.call(
      company: @company,
      kind:    @effective_kind,
      period:  period
    )

    respond_to do |f|
      f.csv do
        send_data build_csv(payload),
          filename: "analytics-#{@company.id}-#{payload[:domain]}-#{period}-#{Time.current.strftime('%Y%m%d-%H%M%S')}.csv",
          type: "text/csv"
      end
      f.pdf { head :not_implemented } # integra Prawn/WickedPDF quando quiseres
      f.any { head :not_acceptable }
    end
  rescue StandardError => e
    Rails.logger.error("[AnalyticsController#export] #{e.class}: #{e.message}")
    redirect_to analytics_path, alert: "Falha ao exportar."
  end

  private

  def set_company!
    @company = (defined?(current_company) && current_company) ||
               (current_user.respond_to?(:company) && current_user.company)
    redirect_to dashboard_path, alert: "Sem empresa associada." and return unless @company
  end

  # Respeita a aba selecionada; fallback para o tipo da empresa; default 'agriculture'
  def set_effective_kind!
    @effective_kind =
      params[:production_kind].presence_in(%w[agriculture aquaculture_sea aquaculture_tank]) ||
      @company.try(:production_kind).presence ||
      "agriculture"
  end

  def safe_period(raw)
    case raw
    when "7d", "quarter", "year" then raw
    else "30d"
    end
  end

  def build_csv(payload)
    require "csv"
    CSV.generate(headers: true) do |csv|
      csv << ["Domain", payload[:domain]]
      csv << ["Updated At", payload[:updated_at]]
      csv << []
      csv << ["KPIs"]
      csv << ["Total",              payload.dig(:kpis, :total)]
      csv << ["Efficiency (%)",     payload.dig(:kpis, :efficiency_pct)]
      csv << ["Costs (€)",          payload.dig(:kpis, :costs_eur)]
      csv << ["Water Quality (%)",  payload.dig(:kpis, :water_quality_pct)]
      csv << []

      if (line = payload.dig(:charts, :line)).present?
        csv << ["Line Chart"]
        csv << ["Category", *line[:series].map { |s| s[:name] }]
        line[:categories].each_with_index do |cat, i|
          csv << [cat, *line[:series].map { |s| s[:data][i] rescue nil }]
        end
        csv << []
      end

      if (bars = payload.dig(:charts, :bars)).present?
        csv << ["Bar Chart"]
        csv << ["Category", *bars[:series].map { |s| s[:name] }]
        bars[:categories].each_with_index do |cat, i|
          csv << [cat, *bars[:series].map { |s| s[:data][i] rescue nil }]
        end
        csv << []
      end

      if (donut = payload.dig(:charts, :donut)).present?
        csv << ["Donut Chart"]
        csv << ["Label", "Value"]
        donut[:labels].each_with_index { |lab, i| csv << [lab, (donut[:data][i] rescue nil)] }
        csv << []
      end

      csv << ["Gauge", payload.dig(:charts, :gauge, :value)]
    end
  end
end
