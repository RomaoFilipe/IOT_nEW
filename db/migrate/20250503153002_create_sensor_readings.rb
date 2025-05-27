class CreateSensorReadings < ActiveRecord::Migration[7.2]
  def change
    create_table :sensor_readings do |t|
      t.references :sensor, null: false, foreign_key: true
      t.float :temperature
      t.float :moisture
      t.integer :battery
      t.integer :signal
      t.datetime :read_at

      t.timestamps
    end
  end
end
