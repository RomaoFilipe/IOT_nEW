# app/helpers/analytics_catalog.rb
module AnalyticsCatalog
  # Mapa: produção -> tabs -> lista de gráficos (partial + id)
  PRODUCTION_UI = {
    "agriculture" => {
      tabs: {
        overview:     "📈 Overview",
        yield:        "🌾 Produção",
        environment:  "🌿 Ambiente & Solo",
        irrigation:   "💧 Irrigação"
      },
      charts: {
        overview: [
          { partial: "analytics/agriculture/overview/yield_over_time",     id: "ag_yield_over_time" },
          { partial: "analytics/agriculture/overview/profit_over_time",    id: "ag_profit_over_time" }
        ],
        yield: [
          { partial: "analytics/agriculture/yield/by_crop",                 id: "ag_yield_by_crop" },
          { partial: "analytics/agriculture/yield/cumulative",              id: "ag_yield_cumulative" }
        ],
        environment: [
          { partial: "analytics/agriculture/env/air_temp",                  id: "ag_air_temp" },
          { partial: "analytics/agriculture/env/soil_moisture",             id: "ag_soil_moisture" },
          { partial: "analytics/agriculture/env/soil_nutrients",            id: "ag_soil_nutrients" }
        ],
        irrigation: [
          { partial: "analytics/agriculture/irrigation/efficiency",         id: "ag_irrig_eff" },
          { partial: "analytics/agriculture/irrigation/cost_per_hectare",   id: "ag_cost_per_ha" }
        ]
      }
    },

    "aquaculture_sea" => {
      tabs: {
        overview: "📊 Overview",
        water:    "🌊 Água Marinha",
        biomass:  "🐟 Biomassa",
        ops:      "🛠️ Operações"
      },
      charts: {
        overview: [
          { partial: "analytics/aquaculture_sea/overview/stock_health",     id: "sea_stock_health" },
          { partial: "analytics/aquaculture_sea/overview/production",       id: "sea_production" }
        ],
        water: [
          { partial: "analytics/aquaculture_sea/water/temperature",         id: "sea_water_temp" },
          { partial: "analytics/aquaculture_sea/water/salinity",            id: "sea_salinity" },
          { partial: "analytics/aquaculture_sea/water/ph",                  id: "sea_ph" },
          { partial: "analytics/aquaculture_sea/water/turbidity",           id: "sea_turbidity" }
        ],
        biomass: [
          { partial: "analytics/aquaculture_sea/biomass/biomass_growth",    id: "sea_biomass_growth" },
          { partial: "analytics/aquaculture_sea/biomass/mortality_rate",    id: "sea_mortality" }
        ],
        ops: [
          { partial: "analytics/aquaculture_sea/ops/alerts",                id: "sea_alerts" },
          { partial: "analytics/aquaculture_sea/ops/energy_costs",          id: "sea_energy_costs" }
        ]
      }
    },

    "aquaculture_tank" => {
      tabs: {
        overview: "📊 Overview",
        water:    "🚰 Água (Tanques)",
        biomass:  "🐟 Biomassa",
        ops:      "🛠️ Operações"
      },
      charts: {
        overview: [
          { partial: "analytics/aquaculture_tank/overview/stock_health",    id: "tank_stock_health" },
          { partial: "analytics/aquaculture_tank/overview/feeding_overview",id: "tank_feeding" }
        ],
        water: [
          { partial: "analytics/aquaculture_tank/water/dissolved_oxygen",   id: "tank_do" },
          { partial: "analytics/aquaculture_tank/water/ammonia",            id: "tank_ammonia" },
          { partial: "analytics/aquaculture_tank/water/temperature",        id: "tank_temp" },
          { partial: "analytics/aquaculture_tank/water/ph",                 id: "tank_ph" }
        ],
        biomass: [
          { partial: "analytics/aquaculture_tank/biomass/biomass_growth",   id: "tank_biomass_growth" },
          { partial: "analytics/aquaculture_tank/biomass/fcr",              id: "tank_fcr" }
        ],
        ops: [
          { partial: "analytics/aquaculture_tank/ops/uptime",               id: "tank_uptime" },
          { partial: "analytics/aquaculture_tank/ops/error_count",          id: "tank_errors" }
        ]
      }
    }
  }.freeze

  DEFAULT = "agriculture"

  module_function

  def config_for(kind)
    PRODUCTION_UI[kind.to_s] || PRODUCTION_UI[DEFAULT]
  end
end
