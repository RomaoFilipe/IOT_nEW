class AddUptimeToSoilReadings < ActiveRecord::Migration[7.2]
  def change
    add_column :soil_readings, :uptime, :integer
  end
end
