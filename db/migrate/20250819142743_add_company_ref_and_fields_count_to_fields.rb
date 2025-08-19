# db/migrate/XXXXXXXXXX_add_company_ref_and_fields_count_to_fields.rb
class AddCompanyRefAndFieldsCountToFields < ActiveRecord::Migration[7.2]
  def change
    add_reference :fields, :company, null: true, foreign_key: true, index: true
    add_column    :fields, :fields_count, :integer, default: 0, null: false
  end
end
