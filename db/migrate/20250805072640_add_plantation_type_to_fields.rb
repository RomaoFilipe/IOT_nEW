class AddPlantationTypeToFields < ActiveRecord::Migration[7.2]
  def change
    add_column :fields, :plantation_type, :string
  end
end
