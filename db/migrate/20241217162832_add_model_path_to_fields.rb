class AddModelPathToFields < ActiveRecord::Migration[7.2]
  def change
    add_column :fields, :model_path, :string
  end
end
