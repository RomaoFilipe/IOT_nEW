class AddNotifEmailAndNotifSmsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :notif_email, :boolean
    add_column :users, :notif_sms, :boolean
  end
end
