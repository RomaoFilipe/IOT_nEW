class CropYield < ApplicationRecord
  belongs_to :field

  validates :crop_type, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :month, presence: true
end