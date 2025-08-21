class AddRawToSensorReadings < ActiveRecord::Migration[7.2]
  def change
    unless column_exists?(:sensor_readings, :raw)
      add_column :sensor_readings, :raw, :jsonb, default: {}, null: true
    end
  end
end
