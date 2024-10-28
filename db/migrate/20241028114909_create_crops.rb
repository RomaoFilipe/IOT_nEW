class CreateCrops < ActiveRecord::Migration[7.2]
  def change
    create_table :crops do |t|
      t.string :name
      t.date :planted_on
      t.date :expected_harvest
      t.text :notes

      t.timestamps
    end
  end
end
