class RemovePositionFromFields < ActiveRecord::Migration[7.2]
  def change
    remove_column :fields, :position_x, :float
    remove_column :fields, :position_y, :float
    remove_column :fields, :position_z, :float
  end
end
