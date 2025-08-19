# app/controllers/analytics_controller.rb
class AnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_company!
  before_action :ensure_production_kind_set!, only: [:index, :data, :export]

  # ------------------------------------------------------------------
  # UI (server-render). A tua view já faz fetch a /analytics/data
  # ------------------------------------------------------------------
  def index
    @effective_kind = @company.production_kind || "agriculture"
    respond_to do |format|
      format.html # render app/views/analytics/index.html.erb
    end
  end

  # ------------------------------------------------------------------
  # JSON para gráficos/KPIs (consumido pelo JS da tua view)
  # GET /analytics/data(.json)?period=7d|30d|quarter|year
  # ------------------------------------------------------------------
  def data
    period = safe_period(params[:period])

    payload = Analytics::BuildData.call(
      company: @company,
      kind:    @company.production_kind || "agriculture",
      period:  period
    )

    # Cache leve de 10s só para não rebentar com refresh agressivo
    response.set_header("Cache-Control", "max-age=10, public")

    render json: payload, status: :ok
  rescue StandardError => e
    Rails.logger.error("[AnalyticsController#data] #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    render json: { error: "Falha ao gerar analytics." }, status: :unprocessable_entity
  end

  # ------------------------------------------------------------------
  # Exportações
  #   /analytics/export.csv?period=30d
  #   /analytics/export.pdf  -> (stub)
  # ------------------------------------------------------------------
  def export
    period = safe_period(params[:period])

    payload = Analytics::BuildData.call(
      company: @company,
      kind:    @company.production_kind || "agriculture",
      period:  period
    )

    respond_to do |format|
      format.csv do
        csv = build_csv(payload)
        send_data csv,
          filename: "analytics-#{@company.id}-#{payload[:domain]}-#{period}-#{Time.current.strftime('%Y%m%d-%H%M%S')}.csv",
          type: "text/csv"
      end

      format.pdf do
        # Mantemos em stub; integra Prawn/WickedPDF quando quiseres
        head :not_implemented
      end

      # fallback
      format.any { head :not_acceptable }
    end
  rescue StandardError => e
    Rails.logger.error("[AnalyticsController#export] #{e.class}: #{e.message}")
    respond_to do |format|
      format.any { redirect_to analytics_path, alert: "Falha ao exportar." }
    end
  end

  private

  # ------------ contexto/segurança ----------------------------------

  def set_company!
    # Ajusta se usares outro nome: current_account, current_team, etc.
    @company = (defined?(current_company) && current_company) ||
               (current_user.respond_to?(:company) && current_user.company)

    unless @company
      redirect_to dashboard_path, alert: "Sem empresa associada." and return
    end
  end

  def ensure_production_kind_set!
    return if @company.production_kind.present?
    # Se não tiver ainda definido, força para agriculture como default (apenas visual),
    # ou então redireciona para settings para escolher o tipo.
    # Aqui optei por deixar visualmente 'agriculture' sem alterar a BD.
    @company.production_kind ||= "agriculture"
  end

  # ------------ helpers ---------------------------------------------

  # Normaliza o período aceito pelo serviço
  def safe_period(raw)
    case raw
    when "7d", "quarter", "year" then raw
    else "30d"
    end
  end

  # Gera um CSV simples e útil a partir do payload do serviço
  # payload esperado:
  # {
  #   domain: "agriculture"|"aquaculture_sea"|"aquaculture_tank",
  #   kpis: { total:, efficiency_pct:, costs_eur:, water_quality_pct: },
  #   charts: {
  #     line:  { categories:[], series:[{name:, data:[]}] },
  #     bars:  { categories:[], series:[{name:, data:[]}] },
  #     donut: { labels:[], data:[] },
  #     gauge: { value: Integer|Nil }
  #   },
  #   updated_at: Time.iso8601
  # }
  def build_csv(payload)
    require "csv"

    CSV.generate(headers: true) do |csv|
      csv << ["Domain", payload[:domain]]
      csv << ["Updated At", payload[:updated_at]]
      csv << []
      csv << ["KPIs"]
      csv << ["Total",            payload.dig(:kpis, :total)]
      csv << ["Efficiency (%)",   payload.dig(:kpis, :efficiency_pct)]
      csv << ["Costs (€)",        payload.dig(:kpis, :costs_eur)]
      csv << ["Water Quality (%)",payload.dig(:kpis, :water_quality_pct)]
      csv << []

      if (line = payload.dig(:charts, :line)).present?
        csv << ["Line Chart"]
        csv << ["Category", *line[:series].map { |s| s[:name] }]
        line[:categories].each_with_index do |cat, idx|
          row = [cat]
          line[:series].each { |s| row << (s[:data][idx] rescue nil) }
          csv << row
        end
        csv << []
      end

      if (bars = payload.dig(:charts, :bars)).present?
        csv << ["Bar Chart"]
        csv << ["Category", *bars[:series].map { |s| s[:name] }]
        bars[:categories].each_with_index do |cat, idx|
          row = [cat]
          bars[:series].each { |s| row << (s[:data][idx] rescue nil) }
          csv << row
        end
        csv << []
      end

      if (donut = payload.dig(:charts, :donut)).present?
        csv << ["Donut Chart"]
        csv << ["Label", "Value"]
        donut[:labels].each_with_index do |lab, idx|
          csv << [lab, (donut[:data][idx] rescue nil)]
        end
        csv << []
      end

      csv << ["Gauge", payload.dig(:charts, :gauge, :value)]
    end
  end
end
