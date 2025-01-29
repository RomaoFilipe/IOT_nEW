class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

         STATUSES = %w[active inactive].freeze

  # Montar o uploader para o campo photo usando CarrierWave
  mount_uploader :photo, PhotoUploader

  # Relacionamentos
  has_many :tasks, dependent: :destroy
  has_many :fields, dependent: :destroy

  # Definir roles com enum
  enum role: { admin: 'admin', manager: 'manager', viewer: 'viewer' }

  # Validações
  validates :role, presence: true
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?
  validates :status, inclusion: { in: STATUSES }

  mount_uploader :photo, PhotoUploader
  # Métodos auxiliares
  def admin?
    role == 'admin'
  end

  def manager?
    role == 'manager'
  end

  def viewer?
    role == 'viewer'
  end
end
