class AddTemperatureToSoilReadings < ActiveRecord::Migration[7.2]
  def change
    add_column :soil_readings, :temperature, :float
  end
end
