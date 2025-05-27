class AddAreaToFields < ActiveRecord::Migration[7.2]
  def change
    add_column :fields, :area, :float
  end
end
