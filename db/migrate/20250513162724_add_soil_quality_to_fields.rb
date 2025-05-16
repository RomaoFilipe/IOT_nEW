class AddSoilQualityToFields < ActiveRecord::Migration[7.2]
  def change
    add_column :fields, :soil_quality, :string
    add_column :fields, :ph_level, :float
    add_column :fields, :last_irrigation_at, :datetime
  end
end
