class CreateFarmTasks < ActiveRecord::Migration[7.2]
  def change
    create_table :farm_tasks do |t|
      t.string :title
      t.text :description
      t.datetime :scheduled_for
      t.boolean :completed
      t.references :field, null: false, foreign_key: true

      t.timestamps
    end
  end
end
