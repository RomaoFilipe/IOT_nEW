class CreateIrrigationSchedules < ActiveRecord::Migration[7.0]
  def change
    create_table :irrigation_schedules do |t|
      t.references :field, null: false, foreign_key: true
      t.references :sensor, null: false, foreign_key: true
      t.integer :day_of_week, null: false   # 0 = Domingo, 6 = Sábado
      t.integer :hour, null: false
      t.integer :minute, null: false
      t.integer :duration, null: false, default: 60  # em segundos
      t.timestamps
    end
  end
end