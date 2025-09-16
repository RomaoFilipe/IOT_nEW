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

  scope :executed_between, ->(from_time, to_time) {
    if column_names.include?("executed_at")
      where.not(executed_at: nil).where(executed_at: from_time..to_time)
    else
      none
    end
  }

 scope :upcoming, ->(limit_count = 10, from_time: Time.zone.now, horizon_hours: 168) {
    all.to_a
       .map { |s| [s, s.next_at(from_time)] }
       .select { |(_s, t)| t && t <= from_time + horizon_hours.hours }
       .sort_by { |(_s, t)| t }
       .first(limit_count)
       .map(&:first)
  }
  scope :executed_between, ->(from_time, to_time) {
    where.not(executed_at: nil).where(executed_at: from_time..to_time)
  }

  def time_hhmm
    format("%02d:%02d", hour, minute)
  end

 # Próxima ocorrência a partir de 'from_time'
  def next_at(from_time = Time.zone.now)
    base_today = Time.zone.local(from_time.year, from_time.month, from_time.day, hour.to_i, minute.to_i)
    days_ahead = (day_of_week.to_i - from_time.wday) % 7
    t = base_today + days_ahead.days
    t += 7.days if t < from_time
    t
  end


  private

  def sensor_matches_field
    return if sensor.nil? || field.nil?
    errors.add(:sensor_id, "não pertence ao campo selecionado") if sensor.field_id != field_id
  end
end
