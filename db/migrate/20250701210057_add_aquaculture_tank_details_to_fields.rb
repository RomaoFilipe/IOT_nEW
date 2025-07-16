class AddAquacultureTankDetailsToFields < ActiveRecord::Migration[7.2]
  def change
    add_column :fields, :species, :string
    add_column :fields, :tank_volume, :float
    add_column :fields, :stocking_density, :float
    add_column :fields, :feeding_regime, :string
    add_column :fields, :fish_placement_date, :date
    add_column :fields, :estimated_harvest_date, :date
  end
end
