class AddAquacultureFieldsToSensors < ActiveRecord::Migration[7.2]
  def change
    add_column :sensors, :ph, :float
    add_column :sensors, :salinity, :float
  end
end
