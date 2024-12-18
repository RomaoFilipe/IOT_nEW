class AddUserIdToFields < ActiveRecord::Migration[7.2]
  def change
    add_column :fields, :user_id, :integer
  end
end
