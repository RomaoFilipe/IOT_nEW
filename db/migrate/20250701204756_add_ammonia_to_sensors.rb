class AddAmmoniaToSensors < ActiveRecord::Migration[7.2]
  def change
    add_column :sensors, :ammonia, :float
  end
end
