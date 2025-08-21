# db/migrate/20250821033318_add_battery_and_signal_to_sensors.rb
class AddBatteryAndSignalToSensors < ActiveRecord::Migration[7.2]
  def change
    add_column :sensors, :battery, :integer unless column_exists?(:sensors, :battery)
    add_column :sensors, :signal,  :integer unless column_exists?(:sensors, :signal)
  end
end
