class AgricultureField < ApplicationRecord
  belongs_to :user
  belongs_to :account
  has_many :sensors, dependent: :destroy

  validates :name, :field_type, :area, :latitude, :longitude, presence: true
  store_accessor :polygon_coordinates
end
