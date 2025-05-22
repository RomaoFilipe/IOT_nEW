class AddExecutedAtToIrrigationSchedules < ActiveRecord::Migration[7.2]
  def change
    add_column :irrigation_schedules, :executed_at, :datetime
  end
end
