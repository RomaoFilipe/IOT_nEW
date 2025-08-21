class AddProductionKindAndCounterToAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :production_kind, :string
    add_index  :accounts, :production_kind
    add_column :accounts, :fields_count, :integer, null: false, default: 0
  end
end
