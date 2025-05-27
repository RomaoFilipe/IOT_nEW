# app/models/sensor.rb
class Sensor < ApplicationRecord

  self.inheritance_column = :type  # Para garantir que 'type' é usado para STI

  belongs_to :field, optional: true
  has_many :sensor_readings, dependent: :destroy
  has_many :irrigation_schedules, dependent: :destroy
  has_many :irrigation_logs, dependent: :destroy
  

  validates :name, presence: true
  validates :device_id, presence: true
  validates :device_id, uniqueness: true, if: -> { new_record? || will_save_change_to_device_id? }
  validates :sensor_type, presence: true
  validates :status, inclusion: { in: %w[Active Inactive parado irrigando] }, allow_nil: true

  def active?
    status == "Active"
  end

  def update_reading(value:, timestamp: Time.current)
    self.last_value = value
    self.last_reading = timestamp
    save!
  end

  # ✅ Tempo restante de irrigação
  def remaining_time
    return 0 unless status == "irrigando" && last_reading && last_duration

    elapsed = Time.current - last_reading
    [last_duration - elapsed.to_i, 0].max
  end
    # ✅ Duração total da última irrigação
    def last_duration
      self[:last_duration] || 60
    end
end
