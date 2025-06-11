class AddAccountToUsers < ActiveRecord::Migration[7.2]
  def change
    add_reference :users, :account, null: true, foreign_key: true
  end
end
