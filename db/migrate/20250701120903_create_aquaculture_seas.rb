class CreateAquacultureSeas < ActiveRecord::Migration[7.2]
  def change
    create_table :aquaculture_seas do |t|
      t.string :name
      t.float :salinity
      t.float :wave_height
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
