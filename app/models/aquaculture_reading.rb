# app/models/aquaculture_reading.rb
class AquacultureReading < ApplicationRecord
  belongs_to :field

  # -----------------------
  # Scopes de filtragem
  # -----------------------
  scope :for_field,  ->(field_id) { where(field_id: field_id) }
  scope :for_fields, ->(ids)      { where(field_id: ids) }
  scope :between,    ->(from, to) { where(measured_at: from..to) }

  # -----------------------
  # Scopes de agregação
  # -----------------------
  # Médias por HORA (para janelas curtas)
  scope :hourly_avg, -> {
    select(
      "date_trunc('hour', measured_at) AS bucket",
      "AVG(temperature)::float  AS temp_avg",
      "AVG(ph)::float           AS ph_avg",
      "AVG(salinity)::float     AS salinity_avg",
      "AVG(oxygen_level)::float AS oxygen_avg"
    ).group("bucket").order("bucket ASC")
  }

  # Médias por DIA (o controller atual agrega por dia)
  scope :daily_avg, -> {
    select(
      "date_trunc('day', measured_at) AS bucket",
      "AVG(temperature)::float  AS temp_avg",
      "AVG(ph)::float           AS ph_avg",
      "AVG(salinity)::float     AS salinity_avg",
      "AVG(oxygen_level)::float AS oxygen_avg"
    ).group("bucket").order("bucket ASC")
  }

  # -----------------------
  # Validações (robustas)
  # -----------------------
  validates :measured_at, presence: true
  validates :temperature,
            presence: true,
            numericality: { greater_than: -5, less_than: 50 }   # -5..50 °C
  validates :ph,
            presence: true,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 14 }

  # Muitos setups não têm sempre salinidade/O2 → opcionais
  validates :salinity,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true
  validates :oxygen_level,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true
end
