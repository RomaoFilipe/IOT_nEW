class IrrigationSchedule < ApplicationRecord
  belongs_to :sensor
  delegate :field, to: :sensor

  validates :day_of_week, :hour, :minute, :duration, presence: true
  validates :hour, inclusion: { in: 0..23 }
  validates :minute, inclusion: { in: 0..59 }
  validates :duration, numericality: { greater_than: 0 }

  # opcional: validar dia da semana
  validates :day_of_week, inclusion: { in: 0..6 }

  validates :sensor_id, uniqueness: {
  scope: [:hour, :minute, :day_of_week],
  message: "já tem um agendamento para este horário"
}

end
