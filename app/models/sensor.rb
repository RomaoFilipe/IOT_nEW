# app/models/sensor.rb
class Sensor < ApplicationRecord
  # ─── Relacionamentos ─────────────────────────────────────
  belongs_to :field, optional: true
  has_many :sensor_readings, dependent: :destroy
  has_many :irrigation_logs, dependent: :destroy
  has_many :irrigation_schedules


  # ─── STI (Single Table Inheritance) ─────────────────────
  # A coluna "type" decide se é TemperatureSensor, IrrigationSensor, etc.

  # ─── Validações ─────────────────────────────────────────
  validates :device_id, presence: true, uniqueness: true
  validates :sensor_type, presence: true, allow_blank: true

  # ─── Callbacks ──────────────────────────────────────────
  after_update_commit :broadcast_irrigation_status, if: :irrigation_status_changed?

  # ─── Escopos ────────────────────────────────────────────
  scope :active, -> { where(active: true) }
  scope :by_type, ->(stype) { where(sensor_type: stype) }

  # ─── Métodos de Negócio ─────────────────────────────────
  
  # Tempo total da última irrigação
  def last_duration
    self[:last_duration] || irrigation_duration || 60
  end

  # Sugestão de campo associado
  def suggested_field
    return nil if Field.none?

    # 1. Por nome semelhante
    similar_by_name = Field.where("name ILIKE ?", "%#{name}%").first
    return similar_by_name if similar_by_name

    # 2. Por proximidade (se tiver coordenadas)
    if respond_to?(:latitude) && respond_to?(:longitude) && latitude.present? && longitude.present?
      Field
        .select("fields.*, (point(latitude, longitude) <-> point(#{latitude}, #{longitude})) AS distance")
        .order("distance ASC")
        .first
    else
      nil
    end
  end

  private

  # Verifica se houve mudança relevante para broadcast
  def irrigation_status_changed?
    saved_change_to_status? ||
      saved_change_to_last_reading? ||
      saved_change_to_irrigation_duration? ||
      saved_change_to_remaining_time?
  end

  # Broadcast via ActionCable (tempo real no dashboard)
  def broadcast_irrigation_status
    ActionCable.server.broadcast("irrigation_status", {
      sensor_id: id,
      remaining_time: remaining_time,
      total_time: irrigation_duration
    })
  end
end
