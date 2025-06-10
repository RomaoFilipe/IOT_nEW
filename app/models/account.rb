class Account < ApplicationRecord
  # 🔗 Relações
  has_many :users, dependent: :destroy
  has_many :fields, dependent: :destroy

  # 🌾 Tipos de exploração disponíveis
  enum farm_type: {
    agriculture: 0,         # Campos agrícolas
    aquaculture_tank: 1,    # Aquacultura em tanques
    aquaculture_sea: 2      # Aquacultura no mar
  }

  # 🛡️ Validações
  validates :nif, presence: true, uniqueness: true
  validates :name, presence: true
end
