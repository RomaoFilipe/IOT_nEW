class AddFieldsToSensorReadings < ActiveRecord::Migration[7.2]
  def change
    add_column :sensor_readings, :status, :string
    add_column :sensor_readings, :remaining_time, :integer
    add_column :sensor_readings, :last_duration, :integer
  end
end
