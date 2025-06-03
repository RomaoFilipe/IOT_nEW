class AddIrrigationSensorIdToIrrigationSchedules < ActiveRecord::Migration[7.2]
  def change
    add_column :irrigation_schedules, :irrigation_sensor_id, :bigint
  end
end
