class CreateTasks < ActiveRecord::Migration[7.2]
  def change
    create_table :tasks do |t|
      t.string :name
      t.text :description
      t.date :date
      t.time :time
      t.string :location
      t.boolean :all_day

      t.timestamps
    end
  end
end
