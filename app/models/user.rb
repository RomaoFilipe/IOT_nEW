class User < ApplicationRecord
  # 🔗 Associações
  belongs_to :account, optional: true
  has_many :tasks, dependent: :destroy
  has_many :fields, dependent: :destroy

  # 🔐 Devise (autenticação)
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  # 📦 Upload de foto
  mount_uploader :photo, PhotoUploader

  # 🌐 Roles (funções no sistema)
  enum role: {
    owner: 'owner',           # Dono da plataforma
    admin: 'admin',           # Dono da conta (empresa)
    manager: 'manager',       # Pode gerir técnicos/viewers
    technician: 'technician', # Operacional de campo
    viewer: 'viewer'          # Apenas leitura
  }

  # 📊 Status do utilizador
  STATUSES = %w[active inactive].freeze

  # 📨 Notificações
  attribute :notif_email, :boolean, default: true
  attribute :notif_sms, :boolean, default: false

  # 🧾 Campo virtual para associação via NIF no registo
  attr_accessor :company_nif

  # ✅ Validações
  validates :role, presence: true
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?
  validates :status, inclusion: { in: STATUSES }

  validates :company_nif, presence: true, if: :requires_nif?
  validates :company_nif, format: { with: /\A\d{9}\z/, message: "deve ter 9 dígitos numéricos" }, allow_blank: true

  # 🧠 Métodos auxiliares de role
  def owner?
    role == 'owner'
  end

  def admin?
    role == 'admin'
  end

  def manager?
    role == 'manager'
  end

  def technician?
    role == 'technician'
  end

  def viewer?
    role == 'viewer'
  end

  def requires_nif?
    admin? || manager?
  end

  private

  def password_required?
    new_record? || password.present?
  end
end
