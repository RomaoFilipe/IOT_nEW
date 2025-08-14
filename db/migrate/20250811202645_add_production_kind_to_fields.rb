class AddProductionKindToFields < ActiveRecord::Migration[7.2]
  def change
    add_column :fields, :production_kind, :string, null: false, default: "agriculture"
    add_index  :fields, :production_kind
  end
end

