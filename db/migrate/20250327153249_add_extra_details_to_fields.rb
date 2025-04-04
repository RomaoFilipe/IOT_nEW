class AddExtraDetailsToFields < ActiveRecord::Migration[7.2]
  def change
    add_column :fields, :notes, :text
    add_column :fields, :planting_date, :date
    add_column :fields, :harvest_date, :date
    add_column :fields, :soil_type, :string
    add_column :fields, :irrigation_type, :string
  end
end
