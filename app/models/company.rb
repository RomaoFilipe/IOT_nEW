# app/models/company.rb
class Company < ApplicationRecord
  has_many :fields, dependent: :destroy

  enum production_kind: {
    agriculture: "agriculture",
    aquaculture_sea: "aquaculture_sea",
    aquaculture_tank: "aquaculture_tank"
  }

  validates :production_kind, inclusion: { in: production_kinds.keys }, allow_nil: true
  validate  :lock_production_kind_if_has_fields, on: :update

  private
  def lock_production_kind_if_has_fields
    return if production_kind_previously_changed? == false
    if production_kind_before_last_save.present? && fields.exists?
      errors.add(:production_kind, "não pode ser alterado enquanto existirem campos. Remova todos os campos primeiro.")
    end
  end
end
