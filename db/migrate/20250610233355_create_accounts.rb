class CreateAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.string :nif, null: false
      t.integer :farm_type, null: false, default: 0  # 0 = agriculture

      t.timestamps
    end

    add_index :accounts, :nif, unique: true
  end
end
