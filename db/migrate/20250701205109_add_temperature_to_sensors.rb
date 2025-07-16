class AddTemperatureToSensors < ActiveRecord::Migration[7.2]
  def change
    add_column :sensors, :temperature, :float
  end
end
