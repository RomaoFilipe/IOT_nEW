class Field < ApplicationRecord
  belongs_to :user
  has_many :crop_yields
  has_many :soil_readings
  has_many :financials
  has_many :sensors, dependent: :destroy
  has_many :irrigation_schedules, dependent: :destroy


  # Validações essenciais
  validates :name, presence: true, length: { maximum: 100 }, uniqueness: { scope: :user_id, message: "Você já tem um campo com esse nome." }
  validates :field_type, presence: true, length: { maximum: 50 }
  validates :latitude, :longitude, presence: true, numericality: true
  validates :area, presence: true, numericality: { greater_than: 0 }
  store_accessor :polygon_coordinates

  # Método para retornar localização formatada
  def formatted_location
    "#{latitude}, #{longitude}" if latitude && longitude
  end
end
