class AddCompanyNifToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :company_nif, :string
  end
end
