class AddAdvancedFieldsToSensorReadings < ActiveRecord::Migration[7.2]
  def change
    add_column :sensor_readings, :light_intensity, :integer
    add_column :sensor_readings, :wind_speed, :float
    add_column :sensor_readings, :wind_direction, :integer
    add_column :sensor_readings, :air_temperature, :float
    add_column :sensor_readings, :air_humidity, :integer
    add_column :sensor_readings, :soil_ph, :float
    add_column :sensor_readings, :soil_ec, :float
    add_column :sensor_readings, :soil_nitrogen, :integer
    add_column :sensor_readings, :soil_potassium, :integer
    add_column :sensor_readings, :soil_phosphorus, :integer
    add_column :sensor_readings, :uptime, :integer
    add_column :sensor_readings, :error_count, :integer
  end
end
