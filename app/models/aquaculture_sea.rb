# app/models/aquaculture_sea.rb
class AquacultureSea < ApplicationRecord
  self.table_name = "aquaculture_seas"

  belongs_to :user
  belongs_to :account
  has_many :sensors, dependent: :destroy

  validates :name, :field_type, :area, :latitude, :longitude, presence: true

  # só usa se tiveres uma coluna json/jsonb chamada `polygon_coordinates`
  store_accessor :polygon_coordinates
end
