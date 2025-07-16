class AddOxygenToSensors < ActiveRecord::Migration[7.2]
  def change
    add_column :sensors, :oxygen, :float
  end
end
