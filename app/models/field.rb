class Field < ApplicationRecord
  # 🔗 Relações
  belongs_to :user
  belongs_to :account
  belongs_to :company, counter_cache: true
  has_many :crop_yields, dependent: :destroy
  has_many :soil_readings, dependent: :destroy
  has_many :financials, dependent: :destroy
  has_many :sensors, dependent: :destroy
  has_many :irrigation_schedules, dependent: :destroy

  # 🗺️ Armazena coordenadas do polígono como JSON
  store_accessor :polygon_coordinates

  # 🌱 Tipos de exploração
  enum field_type: {
    agriculture: 0,
    aquaculture_tank: 1,
    aquaculture_sea: 2
  }

  # ✅ Validações
  validates :name, presence: true, length: { maximum: 100 }, uniqueness: { scope: :user_id, message: "Você já tem um campo com esse nome." }
  validates :field_type, presence: true
  validates :latitude, :longitude, presence: true, numericality: true
  validates :area, presence: true, numericality: { greater_than: 0 }
validates :production_kind, inclusion: { in: Company.production_kinds.keys }
  before_validation :inherit_company_kind


  # 📍 Localização formatada
  def formatted_location
    "#{latitude}, #{longitude}" if latitude && longitude
  end


    private
  def inherit_company_kind
    self.production_kind ||= company&.production_kind
  end
end
