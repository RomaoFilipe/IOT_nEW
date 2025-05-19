class RemoveIrrigationSensorIdFromIrrigationSchedules < ActiveRecord::Migration[7.0]
  def change
    remove_column :irrigation_schedules, :irrigation_sensor_id, :bigint
  end
end
