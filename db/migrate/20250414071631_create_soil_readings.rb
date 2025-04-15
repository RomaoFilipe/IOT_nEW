class CreateSoilReadings < ActiveRecord::Migration[7.2]
  def change
    create_table :soil_readings do |t|
      t.references :field, null: false, foreign_key: true
      t.float :moisture
      t.float :ph
      t.integer :nitrogen
      t.datetime :measured_at

      t.timestamps
    end
  end
end
