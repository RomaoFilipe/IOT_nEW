class AddValuesToSensors < ActiveRecord::Migration[7.2]
  def change
    add_column :sensors, :temperature, :float
    add_column :sensors, :moisture, :float
  end
end
