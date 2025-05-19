class RenameSensorIdToIrrigationSensorIdInIrrigationSchedules < ActiveRecord::Migration[7.2]
  def change
    rename_column :irrigation_schedules, :sensor_id, :irrigation_sensor_id
  end
end
