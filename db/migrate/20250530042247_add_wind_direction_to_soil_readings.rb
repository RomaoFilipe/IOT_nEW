class AddWindDirectionToSoilReadings < ActiveRecord::Migration[7.2]
  def change
    add_column :soil_readings, :wind_direction, :integer
  end
end
