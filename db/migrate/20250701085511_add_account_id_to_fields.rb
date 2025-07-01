class AddAccountIdToFields < ActiveRecord::Migration[7.2]
  def change
    add_reference :fields, :account, null: false, foreign_key: true
  end
end
