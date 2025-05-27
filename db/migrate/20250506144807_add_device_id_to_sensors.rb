class AddDeviceIdToSensors < ActiveRecord::Migration[7.2]
  def change
    add_column :sensors, :device_id, :string
  end
end
