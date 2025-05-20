class AddSoilQualityToFields < ActiveRecord::Migration[7.2]
  def change
    add_column :fields, :soil_quality, :string
  end
end
