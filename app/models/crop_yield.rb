# app/models/crop_yield.rb
class CropYield < ApplicationRecord
  belongs_to :field

  validates :field_id, presence: true
  validates :crop_type, presence: true
  validates :amount, numericality: { greater_than: 0 }

  # Opcional: garantimos que pelo menos um dos campos de tempo existe
  validate :time_reference_present

  private

  def time_reference_present
    if !self.class.column_names.include?("measured_at") && !self.class.column_names.include?("month")
      errors.add(:base, "Modelo sem referência temporal (measured_at ou month).")
    end
  end
end
