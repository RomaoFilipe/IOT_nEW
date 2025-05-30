class AddErrorCountToSoilReadings < ActiveRecord::Migration[7.2]
  def change
    add_column :soil_readings, :error_count, :integer
  end
end
