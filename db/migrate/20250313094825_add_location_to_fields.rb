class AddLocationToFields < ActiveRecord::Migration[7.2]
  def change
    add_column :fields, :latitude, :decimal unless column_exists?(:fields, :latitude)
    add_column :fields, :longitude, :decimal unless column_exists?(:fields, :longitude)
  end
end
