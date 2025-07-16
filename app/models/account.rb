# app/models/account.rb
class Account < ApplicationRecord
  # 🔗 Relacionamentos
  has_many :users, dependent: :destroy
  has_many :fields, dependent: :destroy

  # 🌱 Tipos de exploração agrícola
  enum farm_type: {
    agriculture: 0,
    aquaculture_tank: 1,
    aquaculture_sea: 2
  }

  # ✅ Validações
  validates :name, presence: true
  validates :nif, presence: true, uniqueness: true,
                  format: { with: /\A\d{9}\z/, message: "deve ter 9 dígitos numéricos" }
end

validate :farm_type_cannot_change_if_fields_exist, on: :update

private

def farm_type_cannot_change_if_fields_exist
  if will_save_change_to_farm_type? && fields.exists?
    errors.add(:farm_type, "não pode ser alterado porque já existem campos associados a esta conta.")
  end
end
