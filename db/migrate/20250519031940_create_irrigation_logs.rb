class CreateIrrigationLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :irrigation_logs do |t|
      t.references :sensor, null: false, foreign_key: true
      t.datetime :executed_at
      t.integer :duration
      t.string :status

      t.timestamps
    end
  end
end
