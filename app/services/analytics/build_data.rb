module Analytics
  class BuildData
    def self.call(company:, kind:, period:)
      new(company, kind, period).call
    end

    def initialize(company, kind, period)
      @company, @kind, @period = company, kind, period
      @from = case period
              when "7d"      then 7.days.ago
              when "quarter" then 3.months.ago
              when "year"    then 1.year.ago
              else                 30.days.ago
              end
    end

    def call
      {
        domain: @kind,
        updated_at: Time.current.iso8601,
        kpis: kpis,
        charts: charts
      }
    end

    private

    def kpis
      facts = ProductionFact.for_company(@company).for_period(@from..Time.current).last

      case @kind
      when "aquaculture_sea", "aquaculture_tank"
        rel = AquacultureReading.joins(:field)
                .where(fields: { company_id: @company.id })
                .where("measured_at >= ?", @from)

        # Exemplos simples de KPIs calculados das leituras
        oq = rel.average(:oxygen_level)&.to_f
        ph = rel.average(:ph)&.to_f

        water_quality = if oq && ph
                          score_oxygen = [[(oq - 4.0) * 25, 0].max, 100].min
                          score_ph     = (7.0 - (ph - 7.0).abs) / 7.0 * 100
                          ((score_oxygen + score_ph) / 2.0).round
                        end

        {
          total:          facts&.realized_output_kg || 0,
          efficiency_pct: facts&.efficiency_pct,
          costs_eur:      facts&.costs_eur,
          water_quality_pct: water_quality
        }
      else # "agriculture"
        # adapta aqui se tiveres AgricultureReading
        {
          total:          facts&.realized_output_kg || 0,
          efficiency_pct: facts&.efficiency_pct,
          costs_eur:      facts&.costs_eur,
          water_quality_pct: nil
        }
      end
    end

    def charts
      case @kind
      when "aquaculture_sea", "aquaculture_tank"
        rel = AquacultureReading.joins(:field)
              .where(fields: { company_id: @company.id })
              .where("measured_at >= ?", @from)

        # Linha: temperatura média diária
        by_day = rel.group("DATE(measured_at)").pluck("DATE(measured_at)", Arel.sql("AVG(temperature)"))
        line_categories = by_day.map { |d,_| I18n.l(d, format: "%d/%m") }
        line_series     = [{ name: "Temperatura (°C)", data: by_day.map { |_,v| v&.round(2) } }]

        # Barras: média por campo/tanque
        by_field = rel.group("fields.id", "fields.name").pluck("fields.name", Arel.sql("AVG(temperature)"))
        bars_categories = by_field.map(&:first)
        bars_series     = [{ name: "Temp. média", data: by_field.map { |_,v| v&.round(1) } }]

        # Donut: distribuição por faixas de salinidade
        buckets = { "Baixa" => 0, "Média" => 0, "Alta" => 0 }
        rel.pluck(:salinity).compact.each do |s|
          key = s < 15 ? "Baixa" : (s <= 30 ? "Média" : "Alta")
          buckets[key] += 1
        end

        # Gauge: qualidade da água (do KPI)
        {
          line:  { categories: line_categories, series: line_series },
          bars:  { categories: bars_categories, series: bars_series },
          donut: { labels: buckets.keys, data: buckets.values },
          gauge: { value: kpis[:water_quality_pct] }
        }
      else
        # Placeholders para agricultura (adapta às tuas colunas)
        {
          line:  { categories: [], series: [{name:"Produção", data: []}] },
          bars:  { categories: [], series: [{name:"Despesas", data: []}] },
          donut: { labels: [], data: [] },
          gauge: { value: kpis[:efficiency_pct] }
        }
      end
    end
  end
end
