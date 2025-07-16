class CreateAquacultureTanks < ActiveRecord::Migration[7.2]
  def change
    create_table :aquaculture_tanks do |t|
      t.string :name
      t.float :tank_volume
      t.float :ph_level
      t.float :temperature
      t.float :area
      t.float :latitude
      t.float :longitude
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.jsonb :polygon_coordinates

      t.timestamps
    end
  end
end
