class AddScheduledDayToIrrigationSchedules < ActiveRecord::Migration[7.2]
  def change
    add_column :irrigation_schedules, :scheduled_day, :integer
  end
end
