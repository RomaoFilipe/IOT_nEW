# db/migrate/XXXXXXXXXX_add_production_kind_to_companies.rb
class AddProductionKindToCompanies < ActiveRecord::Migration[7.2]
  def change
    add_column :companies, :production_kind, :string, null: true
    add_index  :companies, :production_kind
  end
end
