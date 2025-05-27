class IrrigationLog < ApplicationRecord
  belongs_to :sensor

  validates :executed_at, presence: true
  validates :duration, presence: true
  validates :status, presence: true
end