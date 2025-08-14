# config/initializers/analytics_catalog.rb
module AnalyticsCatalog
  DEFAULT = "agriculture"

  PRODUCTION_UI = {
    "agriculture" => {
      tabs: {
        overview: "📈 Overview",
        yield:    "🌾 Produção"
      },
      charts: {
        overview: [
          { partial: "analytics/agriculture/overview/yield_over_time",  id: "ag_yield_over_time" },
          { partial: "analytics/agriculture/overview/profit_over_time", id: "ag_profit_over_time" }
        ],
        yield: [
          { partial: "analytics/agriculture/yield/by_crop",    id: "ag_yield_by_crop" },
          { partial: "analytics/agriculture/yield/cumulative", id: "ag_yield_cumulative" }
        ]
      }
    },

    "aquaculture_sea" => {
      tabs: {
        overview: "🌊 Condições da Água",
        oxygen:   "💨 Oxigénio Dissolvido"
      },
      charts: {
        overview: [
          { partial: "analytics/aquaculture_sea/overview/water_temp", id: "sea_water_temp" }
        ],
        oxygen: [
          { partial: "analytics/aquaculture_sea/oxygen/do_levels",    id: "sea_do_levels" }
        ]
      }
    },

    "aquaculture_tank" => {
      tabs: {
        overview: "🚰 Tanque",
        oxygen:   "💨 Oxigénio Dissolvido"
      },
      charts: {
        overview: [
          { partial: "analytics/aquaculture_tank/overview/water_temp", id: "tank_water_temp" }
        ],
        oxygen: [
          { partial: "analytics/aquaculture_tank/oxygen/do_levels",    id: "tank_do_levels" }
        ]
      }
    }
  }.freeze

  module_function

  def config_for(kind)
    PRODUCTION_UI[kind.to_s] || PRODUCTION_UI[DEFAULT]
  end
end
