class CreateCropYields < ActiveRecord::Migration[7.2]
  def change
    create_table :crop_yields do |t|
      t.references :field, null: false, foreign_key: true
      t.string :crop_type       # <-- Já está aqui!
      t.float :amount           # <-- Já está aqui!
      t.string :month
      t.timestamps
    end
  end
end
