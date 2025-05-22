class AddDeviceIdToIrrigationLogs < ActiveRecord::Migration[7.2]
  def change
    add_column :irrigation_logs, :device_id, :string
  end
end
