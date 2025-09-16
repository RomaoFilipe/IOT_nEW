# app/models/field.rb
class Field < ApplicationRecord
  # ───────────── Associations ─────────────
  belongs_to :user
  belongs_to :account

  has_many :sensors,              dependent: :destroy
  has_many :irrigation_schedules, dependent: :destroy
  has_many :soil_readings,        dependent: :destroy
  has_many :financials,           dependent: :destroy
  has_many :crop_yields,          dependent: :destroy
  has_many :aquaculture_readings, class_name: "AquacultureReading",
                                  foreign_key: :field_id,
                                  inverse_of: :field,
                                  dependent: :destroy

  # ───────────── Enums ─────────────
  # field_type é inteiro no schema
  enum field_type: {
    agriculture:       0,
    aquaculture_tank:  1,
    aquaculture_sea:   2
  }, _prefix: true

  # production_kind é string no schema
  enum production_kind: {
    agriculture:       "agriculture",
    aquaculture_tank:  "aquaculture_tank",
    aquaculture_sea:   "aquaculture_sea"
  }, _prefix: true

  # ───────────── Validations ─────────────
  validates :name, presence: true
  validates :user, :account, presence: true

  validates :area,
            presence: true,
            numericality: { greater_than: 0 }

  validates :latitude,  numericality: true, allow_nil: true
  validates :longitude, numericality: true, allow_nil: true

  # usa método de CLASSE para obter as opções do enum
  validates :production_kind,
            inclusion: { in: ->(_rec) { Field.production_kinds.keys } },
            allow_nil: true

  # ───────────── Callbacks ─────────────
before_validation :apply_defaults_from_account, on: :create

  # ───────────── Scopes ─────────────
  scope :recent,      -> { order(updated_at: :desc) }
  scope :with_coords, -> { where.not(latitude: nil, longitude: nil) }

  # ───────────── Helpers ─────────────
  def coords?
    latitude.present? && longitude.present?
  end

  def coords
    coords? ? [latitude.to_f, longitude.to_f] : nil
  end

  # Preferir production_kind (string) para apresentar, senão o field_type
  def human_kind
    (production_kind.presence || field_type).to_s.humanize
  end

  private

  def apply_defaults_from_account
    # garantir user/account (o controller já define, mas por segurança)
    self.user    ||= user
    self.account ||= account

    # Normalizar production_kind a partir do farm_type da account
    if account&.respond_to?(:farm_type) && production_kind.blank?
      ft = account.farm_type.to_s
      self.production_kind = Field.production_kinds.key?(ft) ? ft : "agriculture"
    end

    # Sincronizar field_type (enum int) com production_kind (enum string)
    if field_type.blank? && production_kind.present?
      self.field_type = production_kind
    elsif production_kind.blank? && field_type.present?
      self.production_kind = field_type
    end

    # Estado por omissão
    self.status = "Desconhecido" if status.blank?
  end
end
