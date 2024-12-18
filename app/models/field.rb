class Field < ApplicationRecord
  belongs_to :user

  validates :name, :position_x, :position_y, :position_z, :model_path, presence: true
  validate :validate_model_limit

  private

  # Validação personalizada para limitar o número de modelos
  def validate_model_limit
    case model_path
    when 'trigo2/scene.gltf'
      if user.fields.where(model_path: 'trigo2/scene.gltf').count >= 2
        errors.add(:model_path, "Você só pode ter 2 terrenos do tipo 'trigo2/scene.gltf'.")
      end
    when 'PlaneQuadrado/scene.gltf'
      if user.fields.where(model_path: 'PlaneQuadrado/scene.gltf').count >= 4
        errors.add(:model_path, "Você só pode ter 4 terrenos do tipo 'PlaneQuadrado/scene.gltf'.")
      end
    end
  end
end
