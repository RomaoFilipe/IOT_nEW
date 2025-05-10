class IrrigationSchedule < ApplicationRecord
  belongs_to :field
  belongs_to :sensor

  validates :day_of_week, :hour, :minute, :duration, presence: true
end
