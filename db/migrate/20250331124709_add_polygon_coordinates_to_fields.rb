class AddPolygonCoordinatesToFields < ActiveRecord::Migration[7.2]
  def change
    add_column :fields, :polygon_coordinates, :jsonb
  end
end
