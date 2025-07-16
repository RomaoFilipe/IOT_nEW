class RenameTemperatureToWaterTemperatureInSensors < ActiveRecord::Migration[7.2]
  def change
    rename_column :sensors, :temperature, :water_temperature
  end
end
