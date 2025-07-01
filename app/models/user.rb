class User < ApplicationRecord
  # 🔐 Autenticação com Devise
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  # 📊 Status possíveis
  STATUSES = %w[active inactive].freeze

  # 🖼 Upload da foto de perfil
  mount_uploader :photo, PhotoUploader

  # 🔗 Associações
  belongs_to :account, optional: true
  has_many :tasks, dependent: :destroy
  has_many :fields, dependent: :destroy

  # 🧭 Funções (roles)
  enum role: {
    owner: 'owner',
    admin: 'admin',
    manager: 'manager',
    technician: 'technician',
    viewer: 'viewer'
  }

  # ✅ Validações
  validates :role, presence: true
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?
  validates :status, inclusion: { in: STATUSES }

  # 🧾 Validação do NIF (usado apenas durante sign up)
  attr_accessor :company_nif
  validate :validate_company_nif_requirements, if: :should_validate_nif?

  # ✉️ Preferências de notificação
  attribute :notif_email, :boolean, default: true
  attribute :notif_sms, :boolean, default: false

  # 🔍 Auxiliares de role
  def owner?       = role == 'owner'
  def admin?       = role == 'admin'
  def manager?     = role == 'manager'
  def technician?  = role == 'technician'
  def viewer?      = role == 'viewer'

  private

  def password_required?
    new_record? || password.present?
  end

  def should_validate_nif?
    new_record? && account_id.nil? && !owner?
  end

  def validate_company_nif_requirements
    if company_nif.blank?
      errors.add(:company_nif, "é obrigatório")
    elsif company_nif !~ /\A\d{9}\z/
      errors.add(:company_nif, "deve ter exatamente 9 dígitos")
    end
  end
end
