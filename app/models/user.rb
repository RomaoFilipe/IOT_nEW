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
    owner: 'owner',         # Dono da plataforma
    admin: 'admin',         # Dono da empresa (NIF)
    manager: 'manager',     # Garante gestão da equipa
    technician: 'technician', # Técnico no terreno
    viewer: 'viewer'        # Só leitura
  }

  # ✅ Validações
  validates :role, presence: true
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?
  validates :status, inclusion: { in: STATUSES }

  # 🧾 Associação automática a Account via NIF
  attr_accessor :company_nif
  validates :company_nif, presence: true, if: :requires_nif?
  validates :company_nif, format: { with: /\A\d{9}\z/, message: "deve ter 9 dígitos numéricos" }, allow_blank: true

  # ✉️ Preferências de notificação
  attribute :notif_email, :boolean, default: true
  attribute :notif_sms, :boolean, default: false

  # 🧠 Métodos auxiliares
  def requires_nif?
    admin? || manager?
  end

  def owner?       = role == 'owner'
  def admin?       = role == 'admin'
  def manager?     = role == 'manager'
  def technician?  = role == 'technician'
  def viewer?      = role == 'viewer'

  private

  def password_required?
    new_record? || password.present?
  end
end
