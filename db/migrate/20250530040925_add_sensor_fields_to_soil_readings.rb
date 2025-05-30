class AddSensorFieldsToSoilReadings < ActiveRecord::Migration[7.2]
  def change
    # Removi uptime e error_count porque já existem na tabela

    add_column :soil_readings, :light_intensity, :integer
    add_column :soil_readings, :wind_speed, :float
    add_column :soil_readings, :air_temperature, :float
    add_column :soil_readings, :air_humidity, :integer
    add_column :soil_readings, :soil_ph, :float
    add_column :soil_readings, :soil_ec, :float
    add_column :soil_readings, :soil_nitrogen, :integer
    add_column :soil_readings, :soil_potassium, :integer
    add_column :soil_readings, :soil_phosphorus, :integer
  end
end
