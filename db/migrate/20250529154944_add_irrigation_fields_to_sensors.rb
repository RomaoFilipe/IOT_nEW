class AddIrrigationFieldsToSensors < ActiveRecord::Migration[7.2]
  def change
    add_column :sensors, :irrigation_started_at, :datetime
    add_column :sensors, :irrigation_duration, :integer
  end
end
