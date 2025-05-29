class AddRemainingTimeToSensors < ActiveRecord::Migration[7.2]
  def change
    add_column :sensors, :remaining_time, :integer
  end
end
