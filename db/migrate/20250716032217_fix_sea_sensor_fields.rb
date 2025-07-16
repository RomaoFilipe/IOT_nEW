class FixSeaSensorFields < ActiveRecord::Migration[7.2]
  def change
    add_column :sensors, :current_speed, :float unless column_exists?(:sensors, :current_speed)
    add_column :sensors, :salinity, :float unless column_exists?(:sensors, :salinity)
    add_column :sensors, :oxygen, :float unless column_exists?(:sensors, :oxygen)
    add_column :sensors, :water_temperature, :float unless column_exists?(:sensors, :water_temperature)
  end
end
