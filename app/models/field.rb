class Field < ApplicationRecord
  belongs_to :user

  has_many :sensors, dependent: :destroy
  has_many :irrigation_schedules, dependent: :destroy
  has_many :farm_tasks, dependent: :destroy

  has_many :crop_yields, dependent: :destroy

  has_many :soil_readings, dependent: :restrict_with_error
  has_many :financials, dependent: :restrict_with_error

  # Validações essenciais
  validates :name, presence: true, length: { maximum: 100 }, uniqueness: { scope: :user_id, message: "Você já tem um campo com esse nome." }
  validates :field_type, presence: true, length: { maximum: 50 }
  validates :latitude, :longitude, presence: true, numericality: true
  validates :area, presence: true, numericality: { greater_than: 0 }
  
  store_accessor :polygon_coordinates

  # Localização formatada
  def formatted_location
    "#{latitude}, #{longitude}" if latitude && longitude
  end
end
