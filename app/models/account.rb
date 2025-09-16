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

  validate :farm_type_cannot_change_if_fields_exist, on: :update
  after_update_commit :propagate_farm_type_to_fields, if: :saved_change_to_farm_type?
  
private

  def propagate_farm_type_to_fields
    key  = farm_type.to_s             # "agriculture" | "aquaculture_tank" | "aquaculture_sea"
    intv = Field.field_types[key]     # inteiro do enum de Field (p/ field_type)

    updates = {}
    updates[:field_type]      = intv if Field.column_names.include?("field_type")
    updates[:production_kind] = key  if Field.column_names.include?("production_kind")

    # faz o alinhamento em bulk
    fields.update_all(updates.merge(updated_at: Time.current)) if updates.any?
  end

  def farm_type_cannot_change_if_fields_exist
    if will_save_change_to_farm_type? && fields.exists?
      errors.add(:farm_type, "não pode ser alterado porque já existem campos associados a esta conta.")
    end
  end
end
