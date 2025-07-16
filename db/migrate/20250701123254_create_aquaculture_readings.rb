class CreateAquacultureReadings < ActiveRecord::Migration[7.2]
  def change
    create_table :aquaculture_readings do |t|
      t.references :field, null: false, foreign_key: true
      t.float :temperature
      t.float :ph
      t.float :salinity
      t.float :oxygen_level
      t.datetime :measured_at

      t.timestamps
    end
  end
end
