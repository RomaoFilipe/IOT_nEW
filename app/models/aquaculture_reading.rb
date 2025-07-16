# aquaculture_reading.rb
class AquacultureReading < ApplicationRecord
  belongs_to :field

  validates :temperature, :ph, :salinity, :oxygen_level, :measured_at, presence: true
end
