class CreateCropYields < ActiveRecord::Migration[7.2]
  def change
    create_table :crop_yields do |t|
      t.string :month
      t.integer :corn_yield
      t.integer :wheat_yield

      t.timestamps
    end
  end
end
