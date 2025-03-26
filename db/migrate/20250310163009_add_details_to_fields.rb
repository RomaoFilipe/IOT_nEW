class AddDetailsToFields < ActiveRecord::Migration[7.2]
  def change
    add_column :fields, :humidity, :integer
    add_column :fields, :temperature, :integer
    add_column :fields, :sensors_count, :integer
    add_column :fields, :status, :string
  end
end
