class AddTypeToSensors < ActiveRecord::Migration[7.2]
  def change
    add_column :sensors, :type, :string
    add_index :sensors, :type
  end
end
