class CreateFields < ActiveRecord::Migration[7.2]
  def change
    create_table :fields do |t|
      t.string :name
      t.string :field_type
      t.float :position_x
      t.float :position_y
      t.float :position_z

      t.timestamps
    end
  end
end
