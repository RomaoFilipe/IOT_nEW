# app/models/sensor.rb
class Sensor < ApplicationRecord
  self.inheritance_column = :type

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

  # Alias para clareza
  def irrigation_started_at
    last_reading
  end

  def irrigation_duration
    last_duration
  end

  # Tempo restante de irrigação
  def remaining_time
    return 0 unless status == "irrigando" && irrigation_started_at && irrigation_duration

    elapsed = Time.current - irrigation_started_at
    [irrigation_duration - elapsed.to_i, 0].max
  end

  # Duração total da última irrigação
  def last_duration
    self[:last_duration] || 60
  end

  # WebSocket callback
  after_update_commit :broadcast_irrigation_status, if: :irrigation_status_changed?

  private

def irrigation_status_changed?
  saved_change_to_status? || saved_change_to_last_reading? || saved_change_to_irrigation_duration?
end

  def broadcast_irrigation_status
    ActionCable.server.broadcast("irrigation_status", {
      sensor_id: id,
      remaining_time: remaining_time,
      total_time: irrigation_duration
    })
  end
end
