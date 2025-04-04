class AddBoundaryToFields < ActiveRecord::Migration[7.2]
  def change
    add_column :fields, :field_boundary, :jsonb
  end
end
