class AddManuallyDisabledToSensors < ActiveRecord::Migration[7.2]
  def change
    add_column :sensors, :manually_disabled, :boolean
  end
end
