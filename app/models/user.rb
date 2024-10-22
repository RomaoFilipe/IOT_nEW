class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Montar o uploader para o campo photo usando CarrierWave
  mount_uploader :photo, PhotoUploader
end
