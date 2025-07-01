class ChangeFieldTypeToIntegerInFields < ActiveRecord::Migration[7.2]
  def change
    remove_column :fields, :field_type, :string
    add_column :fields, :field_type, :integer, default: 0, null: false
  end
end
