class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  STATUSES = %w[active inactive].freeze

  # Montar o uploader para foto
  mount_uploader :photo, PhotoUploader

  # Relacionamentos
  has_many :tasks, dependent: :destroy
  has_many :fields, dependent: :destroy

  # Roles
  enum role: { admin: 'admin', manager: 'manager', viewer: 'viewer' }

  # Validações
  validates :role, presence: true
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?
  validates :status, inclusion: { in: STATUSES }

  # Notificações (novos atributos booleanos)
  attribute :notif_email, :boolean, default: true
  attribute :notif_sms, :boolean, default: false

  # Helpers
  def admin?
    role == 'admin'
  end

  def manager?
    role == 'manager'
  end

  def viewer?
    role == 'viewer'
  end

  private

  def password_required?
    new_record? || password.present?
  end
end
