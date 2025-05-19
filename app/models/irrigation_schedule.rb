class IrrigationSchedule < ApplicationRecord
  belongs_to :sensor  # Este relacionamento define que o 'sensor_id' é um atributo válido
  belongs_to :field

  validates :day_of_week, :hour, :minute, :duration, presence: true
end
