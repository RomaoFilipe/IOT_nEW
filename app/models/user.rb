class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Montar o uploader para o campo photo usando CarrierWave
  mount_uploader :photo, PhotoUploader
  has_many :tasks, dependent: :destroy
  has_many :fields, dependent: :destroy

  def admin?
    self.admin
  end
end
