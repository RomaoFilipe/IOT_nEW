class IrrigationSchedule < ApplicationRecord
  # A tua tabela tem field_id e sensor_id → mantemos as duas associações
  belongs_to :field
  belongs_to :sensor

  # Validações
  validates :day_of_week, :hour, :minute, :duration, presence: true
  validates :hour, inclusion: { in: 0..23 }
  validates :minute, inclusion: { in: 0..59 }
  validates :duration, numericality: { greater_than: 0 }
  validates :day_of_week, inclusion: { in: 0..6 }

  validates :sensor_id, uniqueness: {
    scope: [:hour, :minute, :day_of_week],
    message: "já tem um agendamento para este horário"
  }

  # Coerência: o sensor tem de pertencer ao mesmo campo
  validate :sensor_matches_field

  # Scopes usados no Analytics
  scope :for_fields, ->(ids) { where(field_id: ids) }

  scope :upcoming, -> {
    where("executed_at IS NULL OR executed_at > NOW()").order(:day_of_week, :hour, :minute)
  }

  scope :executed_between, ->(from_time, to_time) {
    where.not(executed_at: nil).where(executed_at: from_time..to_time)
  }

  def time_hhmm
    format("%02d:%02d", hour, minute)
  end

  private

  def sensor_matches_field
    return if sensor.nil? || field.nil?
    errors.add(:sensor_id, "não pertence ao campo selecionado") if sensor.field_id != field_id
  end
end
