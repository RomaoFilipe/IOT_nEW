class AddMeasuredAtToIrrigationSchedules < ActiveRecord::Migration[7.2]
  def change
    add_column :irrigation_schedules, :measured_at, :datetime
  end
end
