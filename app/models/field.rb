class Field < ApplicationRecord
  belongs_to :user

  validates :name, :position_x, :position_y, :position_z, :model_path, presence: true
  validate :validate_model_limit

  before_validation :assign_position, on: :create

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

  # Atribuir posição com base em predefinedPositions
  def assign_position
    predefined_positions = {
      'trigo2/scene.gltf' => [{ x: 0, y: 0, z: -2 }, { x: 50, y: 0, z: 0 }],
      'PlaneQuadrado/scene.gltf' => [
        { x: 58, y: 0, z: 57 },
        { x: 58, y: 0, z: 0 },
        { x: 0, y: 0, z: 0 },
        { x: -56, y: 0, z: 112 }
      ]
    }

    used_positions = user.fields.where(model_path: model_path).pluck(:position_x, :position_y, :position_z)
    available_positions = predefined_positions[model_path] - used_positions.map { |pos| { x: pos[0], y: pos[1], z: pos[2] } }

    if available_positions.empty?
      errors.add(:base, "Não há posições disponíveis para este tipo de terreno.")
    else
      self.position_x = available_positions.first[:x]
      self.position_y = available_positions.first[:y]
      self.position_z = available_positions.first[:z]
    end
  end
end
