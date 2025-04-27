class CreateSensors < ActiveRecord::Migration[7.2]
  def change
    create_table :sensors do |t|
      t.string :name
      t.string :sensor_type
      t.string :status
      t.integer :battery
      t.integer :signal
      t.string :last_value
      t.datetime :last_reading
      t.boolean :active
      t.string :icon
      t.references :field, null: false, foreign_key: true

      t.timestamps
    end
  end
end
