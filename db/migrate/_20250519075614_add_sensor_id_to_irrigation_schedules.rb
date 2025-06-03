class AddSensorIdToIrrigationSchedules < ActiveRecord::Migration[7.2]
  def change
    add_reference :irrigation_schedules, :sensor, null: false, foreign_key: true
  end
end
