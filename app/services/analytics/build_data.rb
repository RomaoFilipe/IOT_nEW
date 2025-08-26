# app/services/analytics/build_data.rb
module Analytics
  class BuildData
    def self.call(company:, kind:, period:)
      new(company, kind, period).call
    end

    def initialize(company, kind, period)
      @company = company
      @kind    = kind
      @range   = range_for(period)
      @tz      = Time.zone.name
    end

    def call
      case @kind
      when "agriculture"      then build_agriculture
      when "aquaculture_sea"  then build_aquaculture_sea
      when "aquaculture_tank" then build_aquaculture_tank
      else build_agriculture
      end
    end

    private

    def range_for(period)
      to = Time.zone.now.end_of_day
      from =
        case period
        when "7d"      then 7.days.ago.beginning_of_day
        when "quarter" then 90.days.ago.beginning_of_day
        when "year"    then 1.year.ago.beginning_of_day
        else                 30.days.ago.beginning_of_day
        end
      (from..to)
    end

    def field_ids
      if @company.respond_to?(:fields)
        @company.fields.pluck(:id)
      else
        []
      end
    end

    # =============== AGRICULTURA ==================
    def build_agriculture
      series = build_agriculture_series
      expenses = build_expenses

      kpis = {
        total:             series[:series].sum,
        efficiency_pct:    78,
        costs_eur:         expenses.values.sum,
        water_quality_pct: 84
      }

      {
        domain: "agriculture",
        kpis: kpis,
        charts: {
          line:  { categories: series[:categories], series: [{ name: "Produção (ton)", data: series[:series] }] },
          bars:  { categories: expenses.keys, series: [{ name: "Despesas (€)", data: expenses.values }] },
          donut: { labels: expenses.keys, data: expenses.values },
          gauge: { value: 82 }
        },
        updated_at: Time.zone.now
      }
    end

    def build_agriculture_series
      if defined?(CropYield)
        if CropYield.column_names.include?("measured_at")
          data =
            if defined?(Groupdate)
              # gem 'groupdate'
              CropYield.where(field_id: field_ids, measured_at: @range)
                       .group_by_day(:measured_at, time_zone: @tz).sum(:amount)
            else
              # Fallback sem groupdate
              days = (@range.first.to_date..@range.last.to_date).to_a
              days.index_with do |d|
                CropYield.where(field_id: field_ids, measured_at: d.beginning_of_day..d.end_of_day).sum(:amount).to_f
              end
            end
          cats = data.keys.map { |d| d.is_a?(Date) || d.is_a?(Time) ? d.strftime("%d/%m") : d.to_s }
          vals = data.values.map { |v| v.to_f.round(2) }
          { categories: cats, series: vals }
        elsif CropYield.column_names.include?("month")
          meses = %w[Jan Fev Mar Abr Mai Jun Jul Ago Set Out Nov Dez]
          by_m  = CropYield.where(field_id: field_ids).group(:month).sum(:amount)
          vals  = meses.map { |m| by_m[m].to_f.round(2) }
          { categories: meses, series: vals }
        else
          demo_series(base: 12, noise: 4)
        end
      else
        demo_series(base: 12, noise: 4)
      end
    end

    def build_expenses
      if defined?(Expense)
        Expense.where(company_id: @company.id, date: @range)
               .group(:category).sum(:amount).transform_values { |v| v.to_f.round(2) }
      else
        { "Sementes" => 1200.0, "Fertilizantes" => 2300.0, "Mão-de-obra" => 3200.0, "Combustível" => 900.0 }
      end
    end

    # =============== AQUACULTURA (MAR) ==================
    def build_aquaculture_sea
      line =
        if defined?(AquacultureReading) && AquacultureReading.column_names.include?("measured_at")
          data =
            if defined?(Groupdate)
              AquacultureReading.where(field_id: field_ids, measured_at: @range)
                                .group_by_day(:measured_at, time_zone: @tz).average(:oxygen_level)
            else
              days = (@range.first.to_date..@range.last.to_date).to_a
              days.index_with do |d|
                AquacultureReading.where(field_id: field_ids, measured_at: d.beginning_of_day..d.end_of_day)
                                  .average(:oxygen_level).to_f
              end
            end
          { categories: data.keys.map { |d| d.strftime("%d/%m") },
            series: [{ name: "Oxigénio (mg/L)", data: data.values.map { |v| v.to_f.round(2) } }] }
        else
          d = demo_series(base: 7, noise: 1.5)
          { categories: d[:categories], series: [{ name: "Oxigénio (mg/L)", data: d[:series] }] }
        end

      by_zone =
        if defined?(Catch)
          Catch.where(company_id: @company.id, caught_at: @range)
               .group(:zone).sum(:weight).transform_values { |v| v.to_f.round(2) }
        elsif @company.respond_to?(:fields)
          @company.fields.limit(4).pluck(:name).index_with { rand(200..600).to_f }
        else
          { "Zona A" => 420.0, "Zona B" => 380.0, "Zona C" => 510.0 }
        end

      kpis = {
        total:             by_zone.values.sum,
        efficiency_pct:    74,
        costs_eur:         1850.0,
        water_quality_pct: 88
      }

      {
        domain: "aquaculture_sea",
        kpis: kpis,
        charts: {
          line:  line,
          bars:  { categories: by_zone.keys, series: [{ name: "Captura (kg)", data: by_zone.values }] },
          donut: { labels: %w[Sardinha Cavalinha Robalo Outros], data: [35, 25, 20, 20] },
          gauge: { value: 76 }
        },
        updated_at: Time.zone.now
      }
    end

    # =============== AQUACULTURA (TANQUE) ==================
    def build_aquaculture_tank
      line =
        if defined?(TankProduction)
          data =
            if TankProduction.column_names.include?("measured_at") && defined?(Groupdate)
              TankProduction.where(company_id: @company.id, measured_at: @range)
                            .group_by_day(:measured_at, time_zone: @tz).sum(:kg)
            elsif TankProduction.column_names.include?("measured_at")
              days = (@range.first.to_date..@range.last.to_date).to_a
              days.index_with do |d|
                TankProduction.where(company_id: @company.id, measured_at: d.beginning_of_day..d.end_of_day)
                              .sum(:kg).to_f
              end
            else
              demo = demo_series(base: 9, noise: 2)
              demo[:categories].zip(demo[:series]).to_h
            end
          { categories: data.keys.map { |d| d.is_a?(Date) || d.is_a?(Time) ? d.strftime("%d/%m") : d.to_s },
            series: [{ name: "Produção (kg)", data: data.values.map { |v| v.to_f.round(2) } }] }
        else
          d = demo_series(base: 9, noise: 2)
          { categories: d[:categories], series: [{ name: "Produção (kg)", data: d[:series] }] }
        end

      by_tank =
        if defined?(TankProduction) && TankProduction.column_names.include?("tank_name")
          TankProduction.where(company_id: @company.id, measured_at: @range)
                        .group(:tank_name).sum(:kg).transform_values { |v| v.to_f.round(2) }
        else
          { "Tanque 1" => 320.0, "Tanque 2" => 410.0, "Tanque 3" => 280.0, "Tanque 4" => 350.0 }
        end

      kpis = {
        total:             by_tank.values.sum,
        efficiency_pct:    81,
        costs_eur:         1420.0,
        water_quality_pct: 86
      }

      {
        domain: "aquaculture_tank",
        kpis: kpis,
        charts: {
          line:  line,
          bars:  { categories: by_tank.keys, series: [{ name: "Produção (kg)", data: by_tank.values }] },
          donut: { labels: %w[Dourada Robalo Truta Outros], data: [30, 28, 22, 20] },
          gauge: { value: 84 }
        },
        updated_at: Time.zone.now
      }
    end

    # ———— Helpers de demo ————
    def demo_series(base:, noise:)
      days = (@range.first.to_date..@range.last.to_date).to_a
      vals = days.map { |d| (base + Math.sin(d.yday / 6.0) * noise + rand * noise).round(2) }
      { categories: days.map { |d| d.strftime("%d/%m") }, series: vals }
    end
  end
end
